/**
 * Hold vm2 virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const { NodeVM } = require('vm2');
const cluster = require('cluster');
const path = require('path');

let vm;

exports.buildVM = function buildVM(bundlePath, bundleFileName) {
  vm = new NodeVM({
    require: {
      external: true,
      import: [path.join(bundlePath, bundleFileName)],
      context: 'sandbox',
    },
  });

  console.log(`Built VM for worker #${cluster.worker.id}`);
  console.log('Required objects now in VM sandbox context:', vm.run('module.exports = ReactOnRails'));
  console.log('Required objects should not leak to the global context:', global.ReactOnRails);
  return vm;
};

exports.runInVM = function runInVM(code) {
  return vm.run(`module.exports = ${code}`);
};
