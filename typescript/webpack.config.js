const fs = require('fs');
const path = require('path');
const ZipPlugin = require('zip-webpack-plugin');

module.exports = function (env) {
    const lambdaFunctionDir = path.join(__dirname, 'src', 'lambdas');
    const functionsToBuild = env && env.fxn ? env.fxn.split(",") : fs.readdirSync(lambdaFunctionDir).filter(item => fs.lstatSync(path.join(lambdaFunctionDir, item)).isDirectory() && !item.match(/^\./));
    console.log(`Building ${functionsToBuild.join(", ")}`);

    return functionsToBuild
        .map(fxn => ({
            mode: 'production',
            context: path.resolve(__dirname),
            entry: path.join(lambdaFunctionDir, fxn, 'index.ts'),
            output: {
                path: path.join(__dirname, 'dist', fxn),
                filename: 'index.js',
                libraryTarget: 'commonjs2'
            },
            module: {
                rules: [
                    {
                        test: /\.js$/,
                        use: [
                            {
                                loader: 'babel-loader',
                                options: {
                                    presets: [['@babel/env', {targets: {node: '10.16'}}]],
                                    plugins: [],
                                    compact: false,
                                    babelrc: false,
                                    cacheDirectory: true
                                }
                            }
                        ]
                    },
                    {
                        test: /\.ts(x?)$/,
                        use: [
                            {
                                loader: 'babel-loader',
                                options: {
                                    presets: [['@babel/env', {targets: {node: '10.16'}}]],
                                    plugins: [],
                                    compact: false,
                                    babelrc: false,
                                    cacheDirectory: true
                                }
                            },
                            'ts-loader'
                        ]
                    },
                    {
                        test: /\.jpe?g$|\.gif$|\.png$|\.svg$|\.woff$|\.ttf$|\.wav$|\.mp3$/,
                        use: [
                            'file-loader'
                        ]
                    }
                ]
            },
            resolve: {
                extensions: ['.ts', '.tsx', '.js']
            },
            optimization: {
                minimize: false,
                namedModules: true
            },
            plugins: [
                new ZipPlugin({
                    path: path.join(__dirname, 'dist', fxn),
                    pathPrefix: '',
                    filename: `${fxn}.zip`
                })
            ],
            target: 'node',
            externals: {
                // These modules are already installed on the Lambda instance.
                'aws-sdk': 'aws-sdk',
                'awslambda': 'awslambda',
                'dynamodb-doc': 'dynamodb-doc',
                'imagemagick': 'imagemagick'
            },
            node: {
                // Allow these globals.
                __filename: false,
                __dirname: false
            },
            stats: 'errors-only',
            bail: true
        }));
};
