import * as EventEmitter from 'node:events';

const debounce = <T extends unknown[]>(callback: (...args: T) => void, delay: number) => {
  let timeoutTimer: ReturnType<typeof setTimeout>;

  return (...args: T) => {
    clearTimeout(timeoutTimer);

    timeoutTimer = setTimeout(() => {
      callback(...args);
    }, delay);
  };
};

class AsyncQueue {
  private eventEmitter = new EventEmitter<{ data: any; end: any }>();
  private buffer: string = '';
  private isEnded = false;

  enqueue(value: string) {
    if (this.isEnded) {
      throw new Error('Queue Ended');
    }

    this.buffer += value;
    this.eventEmitter.emit('data', value);
  }

  end() {
    this.isEnded = true;
    this.eventEmitter.emit('end');
  }

  dequeue() {
    return new Promise<string>((resolve, reject) => {
      if (this.isEnded) {
        reject(new Error('Queue Ended'));
        return;
      }

      const checkBuffer = debounce(() => {
        const teardown = () => {
          this.eventEmitter.off('data', checkBuffer);
          this.eventEmitter.off('end', checkBuffer);
        };

        if (this.buffer.length > 0) {
          resolve(this.buffer);
          this.buffer = '';
          teardown();
        } else if (this.isEnded) {
          reject(new Error('Queue Ended'));
          teardown();
        }
      }, 250);

      if (this.buffer.length > 0) {
        checkBuffer();
      }
      this.eventEmitter.on('data', checkBuffer);
      this.eventEmitter.on('end', checkBuffer);
    });
  }

  toString() {
    return '';
  }
}

export default AsyncQueue;
