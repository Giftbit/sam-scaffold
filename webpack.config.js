const failPlugin = require('webpack-fail-plugin');
const fs = require('fs');
const path = require('path');
const ZipPlugin = require('zip-webpack-plugin');

// Enable --fxn=foo to build only that function.
let functionsToBuild = process.argv
    .filter(arg => /^--fxn=/.test(arg))
    .map(arg => arg.substring("--fxn=".length));
if (functionsToBuild.length === 0) {
    functionsToBuild = fs.readdirSync("./src/lambdas");
}
console.log(`Building ${functionsToBuild.join(", ")}`);

module.exports = functionsToBuild
    .map(fxn => ({
        entry: `./src/lambdas/${fxn}/`,
        target: 'node',
        node: {
            // Allow these globals.
            __filename: false,
            __dirname: false
        },
        output: {
            path: `./dist/${fxn}/`,
            filename: 'index.js',
            libraryTarget: 'commonjs2'
        },
        externals: {
            // These modules are already installed on the Lambda instance.
            'aws-sdk': 'aws-sdk',
            'awslambda': 'awslambda',
            'dynamodb-doc': 'dynamodb-doc',
            'imagemagick': 'imagemagick'
        },
        bail: true,
        resolve: {
            extensions: ['', '.webpack.js', '.web.js', '.ts', '.tsx', '.js']
        },
        module: {
            loaders: [
                {
                    test: /\.js$/,
                    loader: 'babel-loader?presets[]=es2015&compact=false'
                },
                {
                    test: /\.json$/,
                    loader: 'json-loader'
                },
                {
                    test: /\.ts$/,
                    loader: 'babel-loader?presets[]=es2015&compact=false!ts-loader'
                },
                {
                    test: /\.jpe?g$|\.gif$|\.png$|\.svg$|\.woff$|\.ttf$|\.wav$|\.mp3$/,
                    loader: "file-loader"
                }
            ]
        },
        plugins: [
            failPlugin,
            new ZipPlugin({
                path: path.join(__dirname, 'dist', fxn),
                pathPrefix: "",
                filename: `${fxn}.zip`
            })
        ]
    }));
