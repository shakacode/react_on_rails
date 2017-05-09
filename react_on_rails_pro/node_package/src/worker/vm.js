/**
 * Hold vm2 virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const { NodeVM, VMScript } = require('vm2');
const cluster = require('cluster');

let vm;
let bundleUpdateTimeUtc;

// Prepare console polyfill script:
// See https://github.com/patriksimek/vm2#vmscript for details:
const consolePolyfillScript = new VMScript(
  `console = { history: [] };
  ['error', 'log', 'info', 'warn'].forEach(function (level) {
    console[level] = function () {
      var argArray = Array.prototype.slice.call(arguments);
      if (argArray.length > 0) {
        argArray[0] = '[SERVER] ' + argArray[0];
      }
      console.history.push({level: level, arguments: argArray});
    };
  });`);

// Prepare console history clearing script:
const clearConsoleHistoryScript = new VMScript('console.history = [];');

/**
 *
 */
exports.buildVM = function buildVMNew(filePath) {
  // See https://github.com/patriksimek/vm2#nodevm for details:
  vm = new NodeVM({
    console: 'off',
    wrapper: 'none',
    require: {
      external: true,
      import: [filePath],
      context: 'sandbox',
    },
  });

  vm.run(consolePolyfillScript);

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
  const result = vm.run(`return ${code}`);
  vm.run(clearConsoleHistoryScript);
  return result;
};
