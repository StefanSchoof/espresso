const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    setupNodeEvents (on, config) {},
    baseUrl: 'http://host.docker.internal',
    supportFile: false
  }
})
