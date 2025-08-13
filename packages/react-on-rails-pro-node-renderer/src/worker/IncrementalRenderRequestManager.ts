import type { ResponseResult } from '../shared/utils';

export interface RenderRequestResult {
  response: ResponseResult;
  shouldContinue: boolean;
}

enum ManagerState {
  // Initial state
  LISTENING = 'listening',
  // After the first object is received
  PROCESSING = 'processing',
  // After the request is finished and all chunks are processed
  STOPPED = 'stopped',
}

export class IncrementalRenderRequestManager {
  private buffered = '';
  private state = ManagerState.LISTENING;
  private firstObjectProcessed = false;

  constructor(
    private readonly onRenderRequestReceived: (data: unknown) => Promise<RenderRequestResult>,
    private readonly onUpdateReceived: (data: unknown) => Promise<void>,
    private readonly onRequestEnded: () => Promise<void>,
    private readonly onResponseStart: (response: ResponseResult) => Promise<void>,
  ) {
    // Constructor parameters are automatically assigned to private readonly properties
  }

  /**
   * Start listening to the request stream
   */
  startListening(req: {
    raw: {
      setEncoding: (encoding: BufferEncoding) => void;
      on(event: 'data', handler: (chunk: string) => void): void;
      on(event: 'end', handler: () => void): void;
      on(event: 'error', handler: (err: unknown) => void): void;
    };
  }): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const source = req.raw;
      source.setEncoding('utf8');

      const handleError = (err: unknown) => {
        this.state = ManagerState.STOPPED;
        reject(err instanceof Error ? err : new Error(String(err)));
      };

      // Set up stream event handlers
      source.on('data', (chunk: string) => {
        if (this.state === ManagerState.STOPPED) return;

        // Simply buffer the data
        this.buffered += chunk;

        // Process the buffer if we haven't processed the first object yet
        if (!this.firstObjectProcessed) {
          void this.processBuffer();
        }
      });

      source.on('end', () => {
        void (async () => {
          try {
            await this.handleRequestEnd();
            resolve();
          } catch (err) {
            handleError(err);
          }
        })();
      });

      source.on('error', (err: unknown) => {
        handleError(err);
      });
    });
  }

  /**
   * Process the buffered data line by line
   */
  private async processBuffer(): Promise<void> {
    if (this.state === ManagerState.STOPPED) return;

    const lines = this.buffered.split('\n');

    // Keep the last line if it's incomplete
    if (lines[lines.length - 1] === '') {
      lines.pop();
    } else {
      // Last line is incomplete, keep it in buffer
      this.buffered = lines.pop() || '';
    }

    // Process complete lines
    for (const line of lines) {
      if (this.state === ManagerState.STOPPED) return;

      try {
        // eslint-disable-next-line no-await-in-loop
        await this.processLine(line);
      } catch (err) {
        console.error('Error processing line:', err);
        this.state = ManagerState.STOPPED;
        return;
      }
    }
  }

  /**
   * Process a single line from the buffer
   */
  private async processLine(line: string): Promise<void> {
    if (this.state === ManagerState.STOPPED) return;

    let obj: unknown;
    try {
      obj = JSON.parse(line);
    } catch (_e) {
      throw new Error(`Invalid NDJSON line: ${line}`);
    }

    if (this.state === ManagerState.LISTENING) {
      // First object - render request
      this.state = ManagerState.PROCESSING;
      this.firstObjectProcessed = true;

      try {
        const result = await this.onRenderRequestReceived(obj);
        await this.onResponseStart(result.response);

        // Check if we should continue processing
        if (!result.shouldContinue) {
          // Stop immediately without processing rest of chunks
          this.state = ManagerState.STOPPED;
          await this.onRequestEnded();
        }
      } catch (err) {
        this.state = ManagerState.STOPPED;
        await this.onRequestEnded();
        throw err;
      }
    } else {
      // We're in PROCESSING state, handle as update
      await this.onUpdateReceived(obj);
    }
  }

  /**
   * Handle the end of the request stream
   */
  private async handleRequestEnd(): Promise<void> {
    if (this.state === ManagerState.STOPPED) return;

    // Process any remaining buffered content
    if (this.buffered.trim()) {
      await this.processBuffer();
    }

    this.state = ManagerState.STOPPED;

    // Call the end callback
    await this.onRequestEnded();
  }

  private isRunning(): boolean {
    return this.state !== ManagerState.STOPPED;
  }
}
