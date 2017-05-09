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
    console: 'off',
    wrapper: 'none',
    require: {
      external: true,
      import: [filePath],
      context: 'sandbox',
    },
  });

  vm.run(`console = { history: [] };
    ['error', 'log', 'info', 'warn'].forEach(function (level) {
    console[level] = function () {
    var argArray = Array.prototype.slice.call(arguments);
    if (argArray.length > 0) {
    argArray[0] = '[SERVER] ' + argArray[0];
    }
    console.history.push({level: level, arguments: argArray});
    };
  });`);

  bundleUpdateTimeUtc = +(fs.statSync(filePath).mtime);

  if (!cluster.isMaster) console.log(`Built VM for worker #${cluster.worker.id}`);
  console.log('Required objects now in VM sandbox context:', vm.run('ReactOnRails') !== undefined);
  console.log('Required objects should not leak to the global context:', global.ReactOnRails);
  return vm;
};

exports.getBundleUpdateTimeUtc = function getBundleUpdateTimeUtc() {
  return bundleUpdateTimeUtc;
};

exports.runInVM = function runInVM(code) {
  const result = vm.run(`return ${code}`);
  vm.run('console.history = []');
  return result;
};
