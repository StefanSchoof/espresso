const path = require('path');
const copyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
    mode: 'production',
    target: 'node',
    entry: {
        'switch': './src/switch/switch.ts'
    },
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: '[name]/[name].js',
        libraryTarget: 'commonjs2'
    },
    module: {
        rules: [
            {
                test: /\.ts$/,
                use: 'awesome-typescript-loader?declaration=false',
                exclude: [/\.(spec|e2e)\.ts$/]
            }
        ]
    },
    resolve: {
        extensions: ['.ts', '.js', '.json'],
        modules: [
            'node_modules',
            'src'
        ]
    },
    plugins: [
        new copyWebpackPlugin([
            {
                from: 'src/host.json',
                to: 'host.json'
            },
            {
                context: 'src',
                from: '**/function.json',
                to: ''
            },
            {
                context: 'src',
                from: '**/local.settings.json',
                to: ''
            }
        ])
    ],
}
