/**
 * Hold vm2 virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const { NodeVM } = require('vm2');
const cluster = require('cluster');
const { clearConsoleHistory } = require('./consoleHistory');

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
  clearConsoleHistory();
  const result = vm.run(`return ${code}`);
  return result;
};

/**
 *
 */
exports.resetVM = function resetVM() {
  vm = undefined;
  bundleUpdateTimeUtc = undefined;
};
