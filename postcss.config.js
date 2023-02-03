module.exports = {
  plugins: [
    require('postcss-import'),
    require('postcss-sassy-mixins'),
    require('postcss-nested'),
    require('postcss-custom-properties')({
      preserve: false
    }),
    require('postcss-hexrgba'),
    require('postcss-preset-env'),
    require('tailwindcss/nesting'),
    require('tailwindcss'),
    require('autoprefixer'),
  ]
}
