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
  //const bundleFullPath = path.join(bundlePath, bundleFileName);
  //vm.run(`require("${bundleFullPath}");`);
  //console.log(vm.run(`console.log(global)`));
  return vm;
}

exports.runInVM = function(code) {
  return vm.run(`module.exports = ${code}`);
}
