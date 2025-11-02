import * as EventEmitter from 'node:events';

class AsyncQueue<T> {
  private eventEmitter = new EventEmitter();

  private buffer: T[] = [];

  private isEnded = false;

  enqueue(value: T) {
    if (this.isEnded) {
      throw new Error('Queue Ended');
    }

    if (this.eventEmitter.listenerCount('data') > 0) {
      this.eventEmitter.emit('data', value);
    } else {
      this.buffer.push(value);
    }
  }

  end() {
    this.isEnded = true;
    this.eventEmitter.emit('end');
  }

  dequeue() {
    return new Promise<T>((resolve, reject) => {
      const bufferValueIfExist = this.buffer.shift();
      if (bufferValueIfExist) {
        resolve(bufferValueIfExist);
      } else if (this.isEnded) {
        reject(new Error('Queue Ended'));
      } else {
        let teardown = () => {};
        const onData = (value: T) => {
          resolve(value);
          teardown();
        };

        const onEnd = () => {
          reject(new Error('Queue Ended'));
          teardown();
        };

        this.eventEmitter.on('data', onData);
        this.eventEmitter.on('end', onEnd);
        teardown = () => {
          this.eventEmitter.off('data', onData);
          this.eventEmitter.off('end', onEnd);
        };
      }
    });
  }
}

export default AsyncQueue;
