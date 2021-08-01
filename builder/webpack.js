'use strict';

var
	path = require('path'),
	glob = require('glob'),
	isGlob = require('is-glob'),
	webpack = require('webpack'),
	MiniCssExtractPlugin = require('mini-css-extract-plugin');

/**
 * Create webpack config from "config" of higher order.
 * This config contains the following fields:
 * - buildSrcPath - string, source path where source modules are located to be processed by webpack
 * - pubPath - string, destination path where to output built files
 * - entries - map: string -> string | glob, contains entries that shal be build
 * - libEntries - array of strings, list of entrypoints that shall be packed into separate libraries. Added to entries
 * - manifestsPath - string, path to directory that contains all library manifests
 * - extLibs - array of strings, list of external libraries that maybe required by this build
 */

function makeConfig(config) {
	var bootstrapSass = path.resolve(config.buildPath, 'node_modules/bootstrap/scss');
	var wpEntries = {};

	Object.entries(config.webpack.entries).forEach(function(entry) {
		wpEntries[entry[0]] = resolveGlobs(entry[1]);
	});

	console.warn('wpEntries');
	console.warn(wpEntries);

	addLibEntries(wpEntries, config.libEntries);

	// Add common rules to pack different kinds of resources
	var rules = [
		{
			test: /\.s[ac]ss$/,
			use: [
				MiniCssExtractPlugin.loader,
				// Translates CSS into CommonJS
				{
					loader: 'css-loader',
					options: {
						sourceMap: true
					}
				},
				// Compiles Sass to CSS
				{
					loader: 'sass-loader',
					options: {
						implementation: require('node-sass'),
						sourceMap: true,
						sassOptions: {
							indentWidth: 4,
							includePaths: [bootstrapSass, config.buildPath],
						}
					}
				}
			]
		},
		{
			test: /\.(png|jpe?g|gif|svg)$/,
			use: [
				{
					loader: 'file-loader',
					options: {
						name: '[path][name].[ext]',
						publicPath: config.publicPath
					}
				}
			]
		}
	];
	// Add basic plugins
	var plugins = [
		// This plugin says that we need
		new webpack.DllPlugin({
			name: '[name]',
			path: path.join(config.manifestsPath, '[name].manifest.json'),
			format: true
		}),
		new MiniCssExtractPlugin({
			// Options similar to the same options in webpackOptions.output
			// both options are optional
			filename: '[name].css',
			chunkFilename: '[id].css',
		})
	];
	// Add plugins to resolve dependencies from other libraries
	addExtLibPlugins(plugins, config.extLibs, config.libraryTarget);

	return {
		context: config.buildPath,
		mode: (config.devMode? 'development': 'production'),
		entry: wpEntries,
		resolve: {
			modules: [
				config.buildPath,
				config.buildAuxPath
			],
			extensions: [
				'.js',
				'.scss'
			],
			symlinks: false
		},
		resolveLoader: {
			modules: [path.join(config.buildPath, 'node_modules')],
			//extensions: ['.js', '.json'],
			//mainFields: ['loader', 'main'],
		},
		module: {
			rules: rules
		},
		plugins: plugins,
		devtool: 'cheap-source-map',
		output: {
			path: config.outPub,
			publicPath: config.publicPath,
			filename: '[name].js',
			libraryTarget: config.libraryTarget,
			library: '[name]'
		}
	};
}

function addExtLibPlugins(plugins, extLibs, libraryTarget) {
	if (!extLibs || !extLibs.length) {
		return;
	}
	extLibs.forEach(function(extLib) {
		var manifestPath = path.join(manifestsPath, extLib + '.manifest.json');
		var mainfest = require(manifestPath);
		plugins.push(new webpack.DllReferencePlugin({
			manifest: mainfest,
			sourceType: libraryTarget
		}));
	});
}

function addLibEntries(entries, libEntries) {
	if (!libEntries || !libEntries.length) {
		return;
	}
	libEntries.forEach(function(it) {
		entries[it] = [it];
	});
}

function globIfIsGlob(tmpl) {
	if (isGlob(tmpl)) {
		return glob.sync(tmpl, {
			follow: true
		});
	}
	return [tmpl];
}

function resolveGlobs(tmpls) {
	if (!(tmpls instanceof Array)) {
		return globIfIsGlob(tmpls);
	}
	var files = [];
	tmpls.forEach(function(tmpl) {
		globIfIsGlob(tmpl).forEach(function(file) {
			files.push(file);
		});
	});
	return files;
}

Object.assign(exports, {
	makeConfig: makeConfig
});