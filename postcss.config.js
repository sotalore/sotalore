module.exports = {
  plugins: [
    require('postcss-import'),
    require('@csstools/postcss-sass'),
    require('tailwindcss/nesting'),
    require('tailwindcss'),
    require('autoprefixer'),
  ]
}
