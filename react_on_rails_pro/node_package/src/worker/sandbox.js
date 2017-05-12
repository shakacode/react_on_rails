/**
 * Hold sandboxed-module instance for rendering code in isolated context.
 * @module worker/sandbox
 */

const fs = require('fs');
const SandboxedModule = require('sandboxed-module');
const cluster = require('cluster');

// Add history to console:
require('console.history');

/**
 * Overrirde _collect method of console.history.
 * See https://github.com/lesander/console.history/blob/master/console-history.js for details.
 */
// eslint-disable-next-line no-underscore-dangle
console._collect = (type, args) => {
  // Act normal, and just pass all original arguments to the origial console function:
  // eslint-disable-next-line prefer-spread
  console[`_${type}`].apply(console, args);

  // Build console history entry in react_on_rails format:
  const argArray = Array.prototype.slice.call(args);
  if (argArray.length > 0) {
    argArray[0] = `[SERVER] ${argArray[0]}`;
  }

  console.history.push({ level: 'log', arguments: argArray });
};

let vm;
let bundleUpdateTimeUtc;

/**
 *
 */
exports.buildVM = function buildVMNew(filePath) {
  bundleUpdateTimeUtc = +(fs.statSync(filePath).mtime);

  fs.appendFileSync(filePath, '; exports.run = function(code) { return eval(code) };');
  vm = SandboxedModule.load(filePath);

  if (!cluster.isMaster) console.log(`Built VM for worker #${cluster.worker.id}`);
  console.log('Required objects now in VM sandbox context:', vm.exports.run('ReactOnRails') !== undefined);
  console.log('Required objects should not leak to the global context:', global.ReactOnRails);
  return vm;
};

/**
 *
 */
exports.getBundleUpdateTimeUtc = function getBundleUpdateTimeUtc() {
  return bundleUpdateTimeUtc;
};

/**
 *
 */
exports.runInVM = function runInVM(code) {
  console.history = [];
  const result = vm.exports.run(code);
  return result;
};

/**
 *
 */
exports.resetVM = function resetVM() {
  vm = undefined;
  bundleUpdateTimeUtc = undefined;
};
