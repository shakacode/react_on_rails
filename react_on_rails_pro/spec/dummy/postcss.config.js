const tailwindcss = require('tailwindcss');
const autoprefixer = require('autoprefixer');

module.exports = {
  plugins: [tailwindcss('./config/tailwind.config.js'), autoprefixer],
};
