const colors = require('tailwindcss/colors');

module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/views/**/*.html.haml',
    './app/helpers/**/*.rb',
    './app/form_builders/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        grey: colors.gray,
        slorange: {
          100:  '#FFE3CD',
          200:  '#f5cca4',
          300:  '#F79300',
          400:  '#df7e00',
          500:  '#CF7000',
          600:  '#9d4800',
          700:  '#7C2E00',
          800:  '#621e00',
          900:  '#3D0600',
        }
      }
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
}
