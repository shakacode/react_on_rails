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

  // Add value to stream
  addStreamValue: function (value) {
    if (!sharedExecutionContext.has('stream')) {
      // Create the stream first if it doesn't exist
      ReactOnRails.getStreamValues();
    }
    const { stream } = sharedExecutionContext.get('stream');
    stream.write(value);
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
