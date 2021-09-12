'use strict';

var
	path = require('path'),
	yargs = require('yargs');

function BuilderConfig(argv) {
	this.devMode = process.env.NODE_ENV !== 'production';
	this.outSite = argv.outSite;
	if (!this.outSite) {
		throw new Error('--outSite option is required to build site');
	}

	if( argv.publicPath ) {
		this.publicPath = argv.publicPath;
	} else {
		this.publicPath = '/pub/';
		console.warn('--publicPath is not set, so using default value: ' + this.publicPath);
	}

	if( argv.outPub ) {
		this.outPub = argv.outPub
	} else if( this.outSite ) {
		this.outPub = path.resolve(
			this.outSite,
			this.publicPath.replace(/^\//, '') // Trim leading slash
		);
		console.warn('--outPub is not set, so using default value: ' + this.outPub);
	}

	if( argv.outTemplates ) {
		this.outTemplates = argv.outTemplates
	} else {
		this.outTemplates = path.resolve(this.outSite, 'res/templates');
		console.warn('--outTemplates is not set, so using default value: ' + this.outTemplates);
	}

	if( argv.manifestsPath ) {
		this.manifestsPath = argv.manifestsPath
	} else {
		this.manifestsPath = path.join(this.outPub, 'manifest/');
		console.warn('--manifestsPath is not set, so using default value: ' + this.manifestsPath);
	}

	if( argv.buildPath ) {
		this.buildPath = argv.buildPath;
	} else {
		this.buildPath = path.resolve(this.outSite, 'build');
		console.warn('--buildPath is not set, so using default value: ' + this.buildPath);
	}

	if( argv.buildAuxPath ) {
		this.buildAuxPath = argv.buildAuxPath;
	} else {
		this.buildAuxPath = path.resolve(this.outSite, 'buildAux');
		console.warn('--buildAuxPath is not set, so using default value: ' + this.buildAuxPath);
	}

	// Path required to be cleaned at start of build
	this.cleanPaths = [];

	this.dependGulpFiles = [];

	this.webpack = {
		entries: {},
		libraryTarget: 'window',
		extLibs: []
	};

	// Paths or globs that should be symlinked to build directory
	this.symlinkBuildPaths = [];

	// Paths or globs that should be symlinked to output directory
	this.symlinkPubPaths = [];
	// Paths or globs that should be symlinked to template resources directory
	this.symlinkTemplatesPaths = [];
}


function resolveConfig() {
	var config = new BuilderConfig(yargs.argv);

	console.log('Command line arguments config resolved: ' + JSON.stringify(config, null, "\t"));
	return config;
};

Object.assign(exports, {
	resolveConfig: resolveConfig
});