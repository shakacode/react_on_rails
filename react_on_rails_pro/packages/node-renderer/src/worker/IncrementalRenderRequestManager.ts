import { FastifyRequest, RouteGenericInterface } from 'fastify';

/**
 * Manages the state and processing of incremental render requests.
 * Handles NDJSON streaming, line parsing, and coordinates callback execution.
 */
export class IncrementalRenderRequestManager {
  private buffered = '';
  private responseFinished = false;
  private firstObjectHandled = false;
  private pendingOperations = new Set<Promise<void>>();
  private isShuttingDown = false;

  constructor(
    private readonly onRenderRequestReceived: (data: unknown) => Promise<void>,
    private readonly onUpdateReceived: (data: unknown) => Promise<void>,
    private readonly onRequestEnded: () => Promise<void>,
  ) {
    // Constructor parameters are automatically assigned to private readonly properties
  }

  /**
   * Start listening to the request stream and handle all events
   * Returns a promise that resolves when the request is complete or rejects on error
   */
  startListening<P extends RouteGenericInterface>(req: FastifyRequest<P>): Promise<void> {
    return new Promise<void>((resolve, reject) => {
      const source = req.raw;
      source.setEncoding('utf8');

      // Set up stream event handlers
      source.on('data', (chunk: string) => {
        // Create and track the operation immediately to prevent race conditions
        const operation = (async () => {
          try {
            await this.processDataChunk(chunk);
          } catch (err) {
            reject(err instanceof Error ? err : new Error(String(err)));
          }
        })();

        // Add to pending operations immediately
        this.pendingOperations.add(operation);

        // Clean up when operation completes
        void operation.finally(() => {
          this.pendingOperations.delete(operation);
        });
      });

      source.on('end', () => {
        void (async () => {
          try {
            await this.handleRequestEnd();
            resolve();
          } catch (err) {
            reject(err instanceof Error ? err : new Error(String(err)));
          }
        })();
      });

      source.on('error', (err: unknown) => {
        reject(err instanceof Error ? err : new Error(String(err)));
      });
    });
  }

  /**
   * Process incoming data chunks and parse NDJSON lines
   */
  private async processDataChunk(chunk: string): Promise<void> {
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
    if (this.isShuttingDown) {
      return;
    }

    let obj: unknown;
    try {
      obj = JSON.parse(line);
    } catch (_e) {
      throw new Error(`Invalid NDJSON line: ${line}`);
    }

    if (!this.firstObjectHandled) {
      // First object - render request
      this.firstObjectHandled = true;
      await this.onRenderRequestReceived(obj);
    } else {
      // Subsequent objects - updates
      await this.onUpdateReceived(obj);
    }
  }

  /**
   * Handle the end of the request stream
   */
  private async handleRequestEnd(): Promise<void> {
    this.isShuttingDown = true;

    // Process any remaining buffered content
    if (this.buffered.trim()) {
      await this.processLine(this.buffered);
      this.buffered = '';
    }

    // Wait for all pending operations to complete
    if (this.pendingOperations.size > 0) {
      await Promise.all(this.pendingOperations);
    }

    // Call the end callback
    await this.onRequestEnded();
  }

  /**
   * Check if the response has been finished
   */
  isResponseFinished(): boolean {
    return this.responseFinished;
  }

  /**
   * Mark the response as finished
   */
  markResponseFinished(): void {
    this.responseFinished = true;
  }
}
