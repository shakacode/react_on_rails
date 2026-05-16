const { PassThrough } = require('stream');

global.ReactOnRails = {
  dummy: { html: 'Dummy Object from secondary bundle' },

  // Get or create stream
  getStreamValues: function () {
    if (!sharedExecutionContext.has('secondaryStream')) {
      const stream = new PassThrough();
      sharedExecutionContext.set('secondaryStream', { stream });
    }
    return sharedExecutionContext.get('secondaryStream').stream;
  },

  // Add value to stream in length-prefixed protocol format
  addStreamValue: function (value) {
    if (!sharedExecutionContext.has('secondaryStream')) {
      ReactOnRails.getStreamValues();
    }
    const { stream } = sharedExecutionContext.get('secondaryStream');
    const meta = JSON.stringify({
      consoleReplayScript: '',
      hasErrors: false,
      isShellReady: true,
      payloadType: 'string',
    });
    const contentBytes = Buffer.byteLength(value, 'utf8');
    const header = meta + '\t' + contentBytes.toString(16).padStart(8, '0') + '\n';
    stream.write(header + value);
  },

  // Add value to first bundle's stream in length-prefixed protocol format
  addStreamValueToFirstBundle: function (value) {
    if (!sharedExecutionContext.has('stream')) {
      ReactOnRails.getStreamValues();
    }
    const { stream } = sharedExecutionContext.get('stream');
    const meta = JSON.stringify({
      consoleReplayScript: '',
      hasErrors: false,
      isShellReady: true,
      payloadType: 'string',
    });
    const contentBytes = Buffer.byteLength(value, 'utf8');
    const header = meta + '\t' + contentBytes.toString(16).padStart(8, '0') + '\n';
    stream.write(header + value);
  },

  endStream: function () {
    if (sharedExecutionContext.has('secondaryStream')) {
      const { stream } = sharedExecutionContext.get('secondaryStream');
      stream.end();
    }
  },

  endFirstBundleStream: function () {
    if (sharedExecutionContext.has('stream')) {
      const { stream } = sharedExecutionContext.get('stream');
      stream.end();
    }
  },

  // Clear all stream values
  clearStreamValues: function () {
    if (sharedExecutionContext.has('secondaryStream')) {
      const { stream } = sharedExecutionContext.get('secondaryStream');
      stream.destroy();
      sharedExecutionContext.delete('secondaryStream');
    }
  },
};
