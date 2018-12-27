const path = require('path');
const TerserPlugin = require('terser-webpack-plugin');

module.exports = {
    mode: 'production',
    target: 'node',
    optimization: {
        minimizer: [new TerserPlugin({ cache: false, parallel: false })],
    },
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
