module.exports = {
  plugins: [
    require('postcss-import'),
    require('postcss-preset-env'),
    require('tailwindcss/nesting'),
    require('tailwindcss'),
    require('autoprefixer'),
  ]
}
