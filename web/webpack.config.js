const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
    mode: 'development',
    devServer: {
        proxy: {
          '/api': 'http://localhost:7071/'
        }
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
        extensions: ['.ts', '.js', '.json']
    },
    plugins: [
        new HtmlWebpackPlugin({
            inject: false,
            template: require('html-webpack-template'),
            title: 'Espresso',
            window: {
                instrumentationKey: '<%INSTRUMENTATION_KEY%>',
                functionsCode: '<%FUNCTIONS_CODE%>',
                functionsHostname: '<%FUNCTIONS_HOSTNAME%>'
            }
        }),
    ]
};
