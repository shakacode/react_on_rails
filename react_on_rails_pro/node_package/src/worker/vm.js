/**
 * Hold vm2 virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const { NodeVM } = require('vm2');
const cluster = require('cluster');
const path = require('path');

let vm;
let bundleUpdateTimeUtc;

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

exports.buildVMNew = function buildVMNew(filepath) {
  const bundlePath = path.resolve(__dirname, '../../../', filepath);

  vm = new NodeVM({
    require: {
      external: true,
      import: [bundlePath],
      context: 'sandbox',
    },
  });

  bundleUpdateTimeUtc = +(fs.statSync(bundlePath).mtime);

  console.log(`Built VM for worker #${cluster.worker.id}`);
  console.log('Required objects now in VM sandbox context:', vm.run('module.exports = ReactOnRails') !== undefined);
  console.log('Required objects should not leak to the global context:', global.ReactOnRails);
  return vm;
};

exports.getBundleUpdateTimeUtc = function getBundleUpdateTimeUtc() {
  return bundleUpdateTimeUtc;
};

exports.runInVM = function runInVM(code) {
  return vm.run(`module.exports = ${code}`);
};
