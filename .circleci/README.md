# CircleCI run policy

Feature branches build only with an open pull request, and newer commits cancel outdated branch workflows (provider settings).

Full checks run for pull requests. The default branch does not repeat the same work after merge; direct pushes require local verification first.

Set the `force_full` pipeline parameter to `true` to request a complete manual run, including on the default branch.

A narrow documentation-only diff runs whitespace and conflict-marker checks, then stops before installing dependencies or running the app suite. Source, HTML lessons, configuration, lockfiles, unknown paths, renamed source files, missing baselines and mixed edits run every existing check. The job still starts briefly to inspect its diff.

Regression check: `node .circleci/should-run.test.mjs`.

Original test commands, assertions, machine sizes and security boundaries are retained. No billing, credentials, fork permissions or production data settings are changed.
