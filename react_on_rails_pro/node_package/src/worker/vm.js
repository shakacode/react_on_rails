/**
 * Hold vm2 virtual machine for rendering code in isolated context.
 * @module worker/vm
 */

const fs = require('fs');
const { NodeVM } = require('vm2');
const cluster = require('cluster');

let vm;
let bundleUpdateTimeUtc;

exports.buildVM = function buildVMNew(filePath) {
  vm = new NodeVM({
    require: {
      external: true,
      import: [filePath],
      context: 'sandbox',
    },
  });

  bundleUpdateTimeUtc = +(fs.statSync(filePath).mtime);

  if (!cluster.isMaster) console.log(`Built VM for worker #${cluster.worker.id}`);
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
