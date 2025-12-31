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

  // Add value to stream
  addStreamValue: function (value) {
    if (!sharedExecutionContext.has('secondaryStream')) {
      // Create the stream first if it doesn't exist
      ReactOnRails.getStreamValues();
    }
    const { stream } = sharedExecutionContext.get('secondaryStream');
    stream.write(value);
  },

  endStream: function () {
    if (sharedExecutionContext.has('secondaryStream')) {
      const { stream } = sharedExecutionContext.get('secondaryStream');
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
