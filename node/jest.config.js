const { defaults: tsjPreset } = require('ts-jest/presets');

module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: tsjPreset.testMatch.filter(t => !t.includes('js')),
  coverageReporters: [
    "cobertura",
    "html",
  ],
};
