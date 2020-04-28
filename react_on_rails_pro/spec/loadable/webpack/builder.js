const _ = require('lodash/fp');

const setTarget = require('./set-target');
const setMode = require('./set-mode');
const setEntry = require('./set-entry');
const setOutput = require('./set-output');
const setContext = require('./set-context');
const setDevtool = require('./set-devtool');
const setDevServer = require('./set-dev-server');
const setModule = require('./set-module');
const setPerformance = require('./set-performance');
const setOptimization = require('./set-optimization');
const setPlugins = require('./set-plugins');
const setResolve = require('./set-resolve');
const setExternals = require('./set-externals');
const setStats = require('./set-stats');
const setWatchOptions = require('./set-watch-options');
const setNode = require('./set-node');

module.exports = (builderConfig) =>
  _.flow(
    setTarget(builderConfig),
    setMode(builderConfig),
    setEntry(builderConfig),
    setOutput(builderConfig),
    setContext(builderConfig),
    setDevtool(builderConfig),
    setDevServer(builderConfig),
    setModule(builderConfig),
    setPerformance(builderConfig),
    setOptimization(builderConfig),
    setPlugins(builderConfig),
    setResolve(builderConfig),
    setExternals(builderConfig),
    setStats(builderConfig),
    setWatchOptions(builderConfig),
    setNode(builderConfig),
  )({});
