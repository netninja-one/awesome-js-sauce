#!/usr/bin/env bash
# Gate expensive CI steps only for a narrowly defined documentation-only diff.
# Unknown ranges, files or fetch failures keep all existing checks enabled.
set -euo pipefail

run_full() {
  printf 'CI gate: running existing checks (%s).\n' "$1"
  exit 0
}

[[ "${CI_FORCE_FULL:-false}" == true ]] && run_full 'explicit full verification'
[[ -n "${CIRCLE_TAG:-}" ]] && run_full 'tag build'
[[ "${CI_DOCS_REPO:-false}" == true ]] && run_full 'documentation or governed repository'
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || run_full 'repository unavailable'

default_branch="${CI_DEFAULT_BRANCH:-}"
[[ -n "$default_branch" ]] || run_full 'default branch unavailable'
git check-ref-format "refs/heads/$default_branch" >/dev/null 2>&1 || run_full 'invalid default branch'

if [[ "${CIRCLE_BRANCH:-}" == "$default_branch" ]]; then
  # The push's base covers every commit in a multi-commit push. HEAD^ does not.
  base="${CI_BASE_REVISION:-}"
  [[ "$base" =~ ^[[:xdigit:]]{40}$|^[[:xdigit:]]{64}$ ]] || run_full 'push base unavailable'
  git cat-file -e "$base^{commit}" 2>/dev/null || run_full 'push base unresolved'
  git merge-base --is-ancestor "$base" HEAD 2>/dev/null || run_full 'push base is not an ancestor'
else
  # Compare the whole branch/PR against the target default branch, not its last commit.
  git fetch --no-tags origin "refs/heads/$default_branch" >/dev/null 2>&1 || run_full 'target branch fetch failed'
  base="$(git merge-base HEAD FETCH_HEAD 2>/dev/null)" || run_full 'branch merge base unresolved'
  [[ -n "$base" ]] || run_full 'branch merge base unavailable'
fi

paths_file="$(mktemp)"
patch_file="$(mktemp)"
trap 'rm -f "$paths_file" "$patch_file"' EXIT
# Disabling rename detection includes both the old and new path. A source file
# renamed to README.md must still run the source checks.
git diff --no-ext-diff --no-renames --name-only -z "$base" HEAD > "$paths_file" || run_full 'changed paths unavailable'
[[ -s "$paths_file" ]] || run_full 'empty diff'
while IFS= read -r -d '' path; do
  case "$path" in
    README*.md) [[ "$path" != */* ]] || run_full 'unknown README directory' ;;
    AGENTS.md|CLAUDE.md|COORDINATION.md|coordination.md|LICENSE|LICENSE.md|LICENSE.txt|docs/*.md) ;;
    *) run_full 'code, configuration or unknown file changed' ;;
  esac
done < "$paths_file"
# Symbolic links or mode changes are structural changes even at documentation paths.
if git diff --no-ext-diff --summary "$base" HEAD | grep -Eq '(mode change|mode 120000)'; then
  run_full 'file type or mode changed'
fi

git diff --no-ext-diff --check "$base" HEAD
git diff --no-ext-diff --no-color --unified=0 "$base" HEAD > "$patch_file"
if grep -Eq '^\+(<{7}([[:space:]]|$)|={7}([[:space:]]|$)|>{7}([[:space:]]|$))' "$patch_file"; then
  printf 'CI gate: added merge-conflict marker in documentation.\n' >&2
  exit 1
fi
printf 'CI gate: documentation-only diff passed whitespace and conflict-marker checks.\n'
circleci-agent step halt
