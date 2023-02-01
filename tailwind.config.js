const colors = require('tailwindcss/colors');

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/views/**/*.html.haml',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        grey: colors.gray,
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
