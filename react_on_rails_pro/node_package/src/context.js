/**
 * Hold VM2 virtual machine for rendering code in isolated context.
 * @module vm
 */

const { NodeVM } = require('vm2');
const path = require('path');

let vm;

exports.buildVM = function(bundlePath, bundleFileName) {
  vm = new NodeVM({
    require: {
      external: true,
      import: [path.join(bundlePath, bundleFileName)],
      context: 'sandbox'
    }
  });

  console.log('BUILD VM')
  return vm;
}

exports.runInVM = function(code) {
  return vm.run(`module.exports = ${code}`);
}
