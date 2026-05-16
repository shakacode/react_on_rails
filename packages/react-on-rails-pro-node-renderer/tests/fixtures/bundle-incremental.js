const { PassThrough } = require('stream');

global.ReactOnRails = {
  dummy: { html: 'Dummy Object' },

  // Get or create stream
  getStreamValues: function () {
    if (!sharedExecutionContext.has('stream')) {
      const stream = new PassThrough();
      sharedExecutionContext.set('stream', { stream });
    }
    return sharedExecutionContext.get('stream').stream;
  },

  // Add value to stream in length-prefixed protocol format
  addStreamValue: function (value) {
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
    return value;
  },

  endStream: function () {
    if (sharedExecutionContext.has('stream')) {
      const { stream } = sharedExecutionContext.get('stream');
      stream.end();
    }
  },

  // Clear all stream values
  clearStreamValues: function () {
    if (sharedExecutionContext.has('stream')) {
      const { stream } = sharedExecutionContext.get('stream');
      stream.destroy();
      sharedExecutionContext.delete('stream');
    }
  },
};
