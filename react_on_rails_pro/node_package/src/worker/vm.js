/**
 * Hold vm2 virtual machine for rendering code in isolated context.
 * @module vm
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
  return vm;
};

exports.runInVM = function runInVM(code) {
  return vm.run(`module.exports = ${code}`);
};
