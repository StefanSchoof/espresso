const path = require('path');

module.exports = {
    mode: 'production',
    target: 'node',
    entry: {
        'switch': './src/switch/switch.js'
    },
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: '[name]/[name].js',
        libraryTarget: 'commonjs2'
    },
    resolve: {
        extensions: ['.ts', '.js', '.json'],
        modules: [
            'node_modules',
            'src'
        ]
    },
}
