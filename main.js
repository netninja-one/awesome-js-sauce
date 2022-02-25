// init the awesomeness
import Awesome from './src/awesome.js'
// Awesome.sauce();

document.getElementById('btn-click').addEventListener('click', function (e) {
    Awesome.sauce()
    e.preventDefault()
})