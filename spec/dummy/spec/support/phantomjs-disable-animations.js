// https://gist.github.com/andyjbas/9962218
// disable_animations.js

// No idea which of these is more helpful.
// They both resulted in crashes:
// https://travis-ci.org/shakacode/react-webpack-rails-tutorial/builds/178794772
// http://marcgg.com/blog/2015/01/05/css-animations-failing-capybara-specs/
var disableAnimationStyles =
  '-webkit-transition: none !important;' +
  '-moz-transition: none !important;' +
  '-ms-transition: none !important;' +
  '-o-transition: none !important;' +
  'transition: none !important;' +
  '-webkit-transition-duration: 0.0s !important;' +
  '-moz-transition-duration: 0.0s !important;' +
  '-ms-transition-duration: 0.0s !important;' +
  '-o-transition-duration: 0.0s  !important;' +
  'transition-duration: 0.0s !important;' +
  'transition-property: none !important;' +
  '-o-transition-property: none !important;' +
  '-moz-transition-property: none !important;' +
  '-ms-transition-property: none !important;' +
  '-webkit-transition-property: none !important;' +
  'transform: none !important;' +
  '-o-transform: none !important;' +
  '-moz-transform: none !important;' +
  '-ms-transform: none !important;' +
  '-webkit-transform: none !important;' +
  'animation: none !important;' +
  '-o-animation: none !important;' +
  '-moz-animation: none !important;' +
  '-ms-animation: none !important;' +
  '-webkit-animation: none !important;';

window.onload = function() {
  var animationStyles = document.createElement('style');
  animationStyles.type = 'text/css';
  animationStyles.innerHTML = '* {' + disableAnimationStyles + '}';
  document.head.appendChild(animationStyles);
};
