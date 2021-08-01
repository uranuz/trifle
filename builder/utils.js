'use strict';

var
	path = require('path'),
	gulp = require('gulp'),
	gulpClean = require('gulp-clean'),
	gutil = require('gulp-util'),
	vfs = require('vinyl-fs'),
	child_process = require('child_process'),
	webpack = require('webpack'),
	tfWebpack = require('./webpack');



function cleanTask(config) {
	return gulp.src(config.cleanPaths, {
		read: false,
		allowEmpty: true
	})
	.pipe(gulpClean({
		force: true
	}));
};

function dependGulpTask(config, gulpFilePath, cb) {
	var resolvedGulpFilePath = path.resolve(gulpFilePath);
	child_process.execFile(
		'/usr/bin/gulp', [
			'--gulpfile=' + resolvedGulpFilePath,
			'--outSite="' + config.outSite + '"'
		],
		{
			cwd: path.dirname(resolvedGulpFilePath) // Set current working dir
		},
		_handleExecResult.bind(null, cb)
	);
};

function symlinkBuildTask(config) {
	return gulp.src(config.symlinkBuildPaths, {
		base: './'
	})
	.pipe(vfs.symlink(config.buildPath, {
		overwrite: false
	}));
};

function symlinkBuildNodeModulesTask(config) {
	var trifle = '/home/uranuz/projects/yar_mkk/trifle';
	return gulp.src(path.join(trifle, 'node_modules/*'), {
		base: path.join(trifle, 'node_modules')
	})
	.pipe(vfs.symlink(path.join(config.buildPath, 'node_modules'), {
		overwrite: false
	}));
}

function setBuildCwdTask(config, cb) {
	console.warn('Switch working dir to build: ', config.buildPath);
	process.chdir(config.buildPath);
	cb();
}

function ivyJSBuilderTask(config, cb) {
	exec(
		'/home/uranuz/projects/yar_mkk/ivy/bin/ivy_js_builder --sourcePath="' + config.outTemplates + '/fir" --outPath="' + config.outPub + '-ivy"',
		{
			//cwd: path.resolve(config.outTemplates) // Set current working dir
		},
		_handleExecResult.bind(null, cb)
	);
};

function _handleExecResult(cb, err, stdout, stderr) {
	console.log(stdout);
	console.log(stderr);
	cb(err);
}

function webpackTask(config, cb) {

	webpack(tfWebpack.makeConfig(config), handleWebpackResult.bind(null, cb));
};


function handleWebpackResult(cb, err, stats) {
	if (err) {
		throw new gutil.PluginError("webpack", err);
	}
	gutil.log("[webpack]", stats.toString({
		stats: 'errors-warnings'
	}));
	if (cb) {
		cb();
	}
}

function symlinkPubTask(config) {
	return gulp.src(config.symlinkPubPaths, {
		base: './'
	})
	.pipe(vfs.symlink(config.outPub));
};


function makeTasks(config) {
	// Create bundles then add nonexisting files as symlinks...

	var allTasks = [];
	// First of all add clean tasks..
	if (config.cleanPaths.length) {
		allTasks.push(cleanTask.bind(null, config));
	}

	// Add dependent gulp tasks before doing tasks of this config
	if (config.dependGulpFiles.length) {
		allTasks.push(gulp.series(config.dependGulpFiles.map(function(filePath) {
			return dependGulpTask.bind(null, config, filePath)
		})));
	}

	// After clean we shall symlink required files to build directory
	if (config.symlinkBuildPaths.length) {
		allTasks.push(symlinkBuildTask.bind(null, config))
	}

	//allTasks.push(setBuildCwdTask.bind(null, config));

	allTasks.push(symlinkBuildNodeModulesTask.bind(null, config));

	// Add webpack task
	if (Object.keys(config.webpack.entries).length) {
		allTasks.push(webpackTask.bind(null, config));
	}
	
	

	// After finishing build we shall symlink result to pub path
	if (config.symlinkPubPaths.length) {
		allTasks.push(symlinkPubTask.bind(null, config));
	}


	//allTasks.push(symlinkTemplatesTask.bind(config));
	//allTasks.push(symlinkBootstrapTask.bind(config));

	//console.log(allTasks);


	return gulp.series(allTasks);
}

function bindFuncs(funcList, config) {
	return funcList.map(function(func) {
		return func.bind(null, config);
	});
}

function symlinkBootstrapTask() {
	return gulp.src(['node_modules/bootstrap/dist/**/*.js'], {
		base: 'node_modules/'
	})
	.pipe(vfs.symlink(sites.mkk.outPub));
};

Object.assign(exports, {
	makeTasks: makeTasks
});