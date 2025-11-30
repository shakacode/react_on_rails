import cluster, { Worker } from 'cluster';
import { randomUUID } from 'crypto';
import { PassThrough, Readable } from 'stream';
import log from './shared/log';

const mapRequestIdToWorker = new Map<string, { from: Worker; to: Worker }>();

type InterWorkerMessage = {
  type: 'inter-worker-message';
  requestId: string;
  messageType: 'initiate' | 'reply' | 'end';
  payload: unknown;
};

const isInterWorkerMessage = (msg: unknown): msg is InterWorkerMessage =>
  typeof msg === 'object' && !!msg && 'type' in msg && msg.type === 'inter-worker-message';

export const routeMessagesFromWorker = (worker: Worker) => {
  if (!cluster.isPrimary) {
    log.error("routeMessagesFromWorker is  called from worker, it's expected to only be called from master");
    return;
  }

  worker.on('message', (msg) => {
    if (!isInterWorkerMessage(msg)) {
      return;
    }
    const workers = Object.values(cluster.workers ?? {}).filter((w) => {
      return worker.id === w?.id || (w?.isConnected() && !w.isScheduledRestart);
    });
    if (workers.length === 0) {
      return;
    }

    const { requestId, messageType } = msg;
    if (messageType === 'initiate') {
      const workersCount = workers.length;
      const workerIndex = workers.findIndex((w) => w?.id === worker.id);
      const otherWorker = workers[workersCount - 1 - workerIndex];
      if (!otherWorker) {
        throw new Error("Can't find a worker to forward the message to");
      }

      if (!otherWorker) {
        return;
      }

      mapRequestIdToWorker.set(requestId, { from: worker, to: otherWorker });
      otherWorker.send(msg);
    } else if (messageType === 'reply' || messageType === 'end') {
      const requestInfo = mapRequestIdToWorker.get(requestId);
      if (!requestInfo) {
        return;
      }

      requestInfo.from.send(msg);
    } else {
      throw new Error(`Unexpected inter worker message type: "${messageType}"`);
    }

    if (messageType === 'end') {
      mapRequestIdToWorker.delete(requestId);
    }
  });
};

type ReceivedMessage = {
  payload: unknown;
  reply: (payload: unknown, close?: boolean) => void;
};

const onMessageInitiatedCallbacks: (() => void)[] = [];
const onMessageEndedCallbacks: (() => void)[] = [];

export const onMessageInitiated = (callback: () => void) => {
  onMessageInitiatedCallbacks.push(callback);
};

export const onMessageEnded = (callback: () => void) => {
  onMessageEndedCallbacks.push(callback);
};

export const onMessageReceived = (callback: (receivedMessage: ReceivedMessage) => void) => {
  process.on('message', (msg) => {
    if (!isInterWorkerMessage(msg)) {
      return;
    }

    const { requestId, payload, messageType } = msg;
    if (messageType === 'initiate') {
      callback({
        payload,
        reply: (replyPayload, close = false) => {
          const replyMsg: InterWorkerMessage = {
            type: 'inter-worker-message',
            messageType: close ? 'end' : 'reply',
            payload: replyPayload,
            requestId,
          };
          process.send?.(replyMsg);

          if (close) {
            onMessageEndedCallbacks.forEach((onMessageEndedCallback) => {
              setTimeout(onMessageEndedCallback, 0);
            });
          }
        },
      });

      onMessageInitiatedCallbacks.forEach((onMessageInitiatedCallback) => {
        setTimeout(onMessageInitiatedCallback, 0);
      });
    }
  });
};

export const sendMessage = (initialPayload: unknown): Readable => {
  const requestId = randomUUID();
  const reveivedStream = new PassThrough();

  onMessageInitiatedCallbacks.forEach((onMessageInitiatedCallback) => {
    setTimeout(onMessageInitiatedCallback, 0);
  });

  process.on('message', function messageReceivedCallback(msg) {
    // If number of workers are small (1 or 2), the request can be redirected to the same worker
    // So, ignore initiate message, it should be handled by the onMessageReceived not the sendMessage function
    if (!isInterWorkerMessage(msg) || msg.requestId !== requestId || msg.messageType === 'initiate') {
      return;
    }

    const { payload, messageType } = msg;
    if (payload) {
      reveivedStream.push(payload);
    }
    if (messageType === 'end') {
      reveivedStream.push(null);
      process.off('message', messageReceivedCallback);
      onMessageEndedCallbacks.forEach((onMessageEndedCallback) => {
        setTimeout(onMessageEndedCallback, 0);
      });
    }
  });

  const initiateMessage: InterWorkerMessage = {
    type: 'inter-worker-message',
    messageType: 'initiate',
    payload: initialPayload,
    requestId,
  };
  process.send?.(initiateMessage);

  return reveivedStream;
};
