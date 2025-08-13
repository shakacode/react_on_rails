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
  // After the request is finished and pending operations are still running
  SHUTTING_DOWN = 'shutting_down',
  // After the request is finished and all pending operations are complete,
  // and the request is closed
  STOPPED = 'stopped',
}

/**
 * Manages the state and processing of incremental render requests.
 * Handles NDJSON streaming, line parsing, and coordinates callback execution.
 */
export class IncrementalRenderRequestManager {
  private buffered = '';
  private responseFinished = false;
  private state = ManagerState.LISTENING;
  private pendingOperations?: Promise<void>;

  constructor(
    private readonly onRenderRequestReceived: (data: unknown) => Promise<RenderRequestResult>,
    private readonly onUpdateReceived: (data: unknown) => Promise<void>,
    private readonly onRequestEnded: () => Promise<void>,
    private readonly onResponseStart: (response: ResponseResult) => Promise<void>,
  ) {
    // Constructor parameters are automatically assigned to private readonly properties
  }

  /**
   * Start listening to the request stream and handle all events
   * Returns a promise that resolves when the request is complete or rejects on error
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
        if (!this.isRunning()) {
          return;
        }

        // Create and track the operation immediately to prevent race conditions
        const executeOperation = async () => {
          try {
            await this.processDataChunk(chunk);
          } catch (err) {
            handleError(err);
          }
        };

        if (this.pendingOperations) {
          this.pendingOperations = this.pendingOperations.then(() => {
            return executeOperation();
          });
        } else {
          this.pendingOperations = executeOperation();
        }
      });

      source.on('end', () => {
        void (async () => {
          try {
            await this.handleRequestEnd(true);
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
   * Process incoming data chunks and parse NDJSON lines
   */
  private async processDataChunk(chunk: string): Promise<void> {
    if (!this.isRunning()) {
      return;
    }

    this.buffered += chunk;

    const lines = this.buffered.split(/\r?\n/);
    this.buffered = lines.pop() ?? '';

    // Process complete lines immediately
    for (const line of lines) {
      if (line.trim()) {
        // eslint-disable-next-line no-await-in-loop
        await this.processLine(line);
      }
    }
  }

  /**
   * Process a single NDJSON line
   */
  private async processLine(line: string): Promise<void> {
    let obj: unknown;
    try {
      obj = JSON.parse(line);
    } catch (_e) {
      throw new Error(`Invalid NDJSON line: ${line}`);
    }

    if (this.state === ManagerState.LISTENING) {
      // First object - render request
      this.state = ManagerState.PROCESSING;

      const result = await this.onRenderRequestReceived(obj);

      // Send the response immediately
      await this.onResponseStart(result.response);

      // Check if we should continue processing
      if (!result.shouldContinue) {
        await this.handleRequestEnd(false);
      }
    } else if (this.state === ManagerState.PROCESSING) {
      // Subsequent objects - updates (only if we're still processing)
      await this.onUpdateReceived(obj);
    }
  }

  /**
   * Handle the end of the request stream
   */
  private async handleRequestEnd(waitUntilAllPendingOperations: boolean): Promise<void> {
    // Only proceed if we haven't already stopped
    if (!this.isRunning()) {
      return;
    }

    if (waitUntilAllPendingOperations) {
      this.state = ManagerState.SHUTTING_DOWN;

      // Wait for all pending operations to complete
      if (this.pendingOperations) {
        await this.pendingOperations;
      }

      // Process any remaining buffered content
      if (this.buffered.trim()) {
        await this.processLine(this.buffered);
        this.buffered = '';
      }
    }

    this.state = ManagerState.STOPPED;
    // Call the end callback
    await this.onRequestEnded();
  }

  private isRunning(): boolean {
    return [ManagerState.LISTENING, ManagerState.PROCESSING].includes(this.state);
  }
}
