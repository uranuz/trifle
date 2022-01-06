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
	var wpCfg = config.webpack;
	var bootstrapSass = path.resolve(config.buildPath, 'node_modules/bootstrap/scss');
	var wpEntries = {};

	Object.entries(wpCfg.entries).forEach(function(entry) {
		wpEntries[entry[0]] = resolveGlobs(entry[1]);
	});

	console.warn('wpEntries');
	console.warn(wpEntries);

	addLibEntries(wpEntries, config.libEntries);

	// Add common rules to pack different kinds of resources
	var rules = [
		{
			test: /\.tsx?$/,
			use: 'ts-loader',
			exclude: /node_modules/,
		},
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
			type: 'asset/resource',
			generator: {
				filename: '[file]'
			}
		}
	];
	// Add basic plugins
	var plugins = [
		// This plugin says that we need
		new webpack.DllPlugin({
			name: '[name]',
			path: path.join(wpCfg.manifestsPath, '[name].manifest.json'),
			format: true
		}),
		new MiniCssExtractPlugin({
			// Options similar to the same options in webpackOptions.output
			// both options are optional
			filename: '[name].css',
			chunkFilename: '[id].css',
		}),
		new webpack.NormalModuleReplacementPlugin(
			/\.ivy$/,
			function (resource) {
				resource.request = path.join('buildAux', resource.request + '.js')
			}
		)
	];
	// Add plugins to resolve dependencies from other libraries
	addExtLibPlugins(plugins, wpCfg);

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
				'.tsx',
				'.ts',
				'.js',
				'.scss'
			],
			symlinks: false
		},
		resolveLoader: {
			modules: [path.join(config.buildPath, 'node_modules')]
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
			libraryTarget: wpCfg.libraryTarget,
			library: '[name]'
		}
	};
}

function addExtLibPlugins(plugins, wpCfg) {
	if (!wpCfg.extLibs || !wpCfg.extLibs.length) {
		return;
	}
	wpCfg.extLibs.forEach(function(extLib) {
		var manifestPath = path.join(wpCfg.manifestsPath, extLib + '.manifest.json');
		var mainfest = require(manifestPath);
		plugins.push(new webpack.DllReferencePlugin({
			manifest: mainfest,
			sourceType: wpCfg.libraryTarget
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