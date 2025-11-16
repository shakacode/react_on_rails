global.ReactOnRails = {
  dummy: { html: 'Dummy Object from secondary bundle' },

  // Get or create async value promise
  getAsyncValue: function () {
    if (!sharedExecutionContext.has('secondaryAsyncPromise')) {
      const promiseData = {};
      const promise = new Promise((resolve, reject) => {
        promiseData.resolve = resolve;
        promiseData.reject = reject;
      });
      promiseData.promise = promise;
      sharedExecutionContext.set('secondaryAsyncPromise', promiseData);
    }
    return sharedExecutionContext.get('secondaryAsyncPromise').promise;
  },

  // Resolve the async value promise
  setAsyncValue: function (value) {
    if (!sharedExecutionContext.has('secondaryAsyncPromise')) {
      ReactOnRails.getAsyncValue();
    }
    const promiseData = sharedExecutionContext.get('secondaryAsyncPromise');
    promiseData.resolve(value);
  },

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
};
