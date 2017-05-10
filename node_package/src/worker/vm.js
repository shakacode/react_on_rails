/**
 * Hold vm2 virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const { NodeVM } = require('vm2');
const cluster = require('cluster');

// Add history to console:
require('console.history');

/**
 * Overrirde _collect method of console.history.
 * See https://github.com/lesander/console.history/blob/master/console-history.js for details.
 */
console._collect = (type, args) => {
  // Act normal, and just pass all original arguments to the origial console function:
  console[`_${type}`].apply(console, args);

  // Build console history entry in react_on_rails format:
  const argArray = Array(Array.prototype.slice.call(args));
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
  // See https://github.com/patriksimek/vm2#nodevm for details:
  vm = new NodeVM({
    console: 'inherit',
    wrapper: 'none',
    require: {
      external: true,
      import: [filePath],
      context: 'sandbox',
    },
  });

  bundleUpdateTimeUtc = +(fs.statSync(filePath).mtime);

  if (!cluster.isMaster) console.log(`Built VM for worker #${cluster.worker.id}`);
  console.log('Required objects now in VM sandbox context:', vm.run('ReactOnRails') !== undefined);
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
  const result = vm.run(`return ${code}`);
  return result;
};
