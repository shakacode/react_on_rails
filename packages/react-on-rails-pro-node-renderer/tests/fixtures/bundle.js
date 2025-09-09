const { PassThrough } = require('stream');

global.ReactOnRails = {
  dummy: { html: 'Dummy Object' },
  
  // Get or create async value promise
  getAsyncValue: function() {
    debugger;
    if (!sharedExecutionContext.has('asyncPromise')) {
      const promiseData = {};
      const promise = new Promise((resolve, reject) => {
        promiseData.resolve = resolve;
        promiseData.reject = reject;
      });
      promiseData.promise = promise;
      sharedExecutionContext.set('asyncPromise', promiseData);
    }
    return sharedExecutionContext.get('asyncPromise').promise;
  },
  
  // Resolve the async value promise
  setAsyncValue: function(value) {
    debugger;
    if (!sharedExecutionContext.has('asyncPromise')) {
      ReactOnRails.getAsyncValue();
    }
    const promiseData = sharedExecutionContext.get('asyncPromise');
    promiseData.resolve(value);
  },
  
  // Get or create stream
  getStreamValues: function() {
    if (!sharedExecutionContext.has('stream')) {
      const stream = new PassThrough();
      sharedExecutionContext.set('stream', { stream });
    }
    return sharedExecutionContext.get('stream').stream;
  },
  
  // Add value to stream
  addStreamValue: function(value) {
    if (!sharedExecutionContext.has('stream')) {
      // Create the stream first if it doesn't exist
      ReactOnRails.getStreamValues();
    }
    const { stream } = sharedExecutionContext.get('stream');
    stream.write(value);
    return value;
  },

  endStream: function() {
    if (sharedExecutionContext.has('stream')) {
      const { stream } = sharedExecutionContext.get('stream');
      stream.end();
    }
  },
};
