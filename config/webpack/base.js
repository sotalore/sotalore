const { webpackConfig, merge } = require('@rails/webpacker')
const webpack = require('webpack')

const customConfig = {
  resolve: {
    extensions: ['.css', '.scss']
  },
  plugins: [
    new webpack.ProvidePlugin({
      "$":"jquery",
      "jQuery":"jquery",
      "window.jQuery":"jquery"
    })
  ]
}

module.exports = merge(webpackConfig, customConfig)
