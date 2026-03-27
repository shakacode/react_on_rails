// Minimal bundle that exposes Node.js Readable for stream-error tests.
// `require` is available here because the VM runs bundles with supportModules: true.
global.Readable = require('stream').Readable;
