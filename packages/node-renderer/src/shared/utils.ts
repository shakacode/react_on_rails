import cluster from 'cluster';
import path from 'path';
import fsExtra from 'fs-extra';
import errorReporter from './errorReporter';
import { getConfig } from './configBuilder';
import log from './log';

export const TRUNCATION_FILLER = '\n... TRUNCATED ...\n';

export function workerIdLabel() {
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
  const workerId = cluster?.worker?.id || 'NO WORKER ID';
  return workerId;
}

// From https://stackoverflow.com/a/831583/1009332
export function smartTrim(value: unknown, maxLength = getConfig().maxDebugSnippetLength) {
  let string;
  if (value == null) return null;

  if (typeof value === 'string') {
    string = value;
  } else if (value instanceof String) {
    string = value.toString();
  } else {
    string = JSON.stringify(value);
  }

  if (maxLength < 1) return string;
  if (string.length <= maxLength) return string;
  if (maxLength === 1) return string.substring(0, 1) + TRUNCATION_FILLER;

  const midpoint = Math.ceil(string.length / 2);
  const toRemove = string.length - maxLength;
  const lstrip = Math.ceil(toRemove / 2);
  const rstrip = toRemove - lstrip;
  return string.substring(0, midpoint - lstrip) + TRUNCATION_FILLER + string.substring(midpoint + rstrip);
}

export interface ResponseResult {
  headers: { 'Cache-Control'?: string };
  status: number;
  data?: unknown;
}

export function errorResponseResult(msg: string): ResponseResult {
  errorReporter.notify(msg);
  return {
    headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
    status: 400,
    data: msg,
  };
}

/**
 *
 * @param renderingRequest JavaScript code to execute
 * @param error
 * @returns {string}
 */
export function formatExceptionMessage(renderingRequest: string, error: any, context?: string) {
  return `${context ? `\nContext:\n${context}\n` : ''}
JS code for rendering request was:
${smartTrim(renderingRequest)}
    
EXCEPTION MESSAGE:
${error.message || error}

STACK:
${error.stack}`;
}

export interface Asset {
  file: string;
  filename: string;
}

/**
 *
 * @param uploadedAssets array of objects with values { file, filename }
 * @returns {Promise<void>}
 */
export async function moveUploadedAssets(uploadedAssets: Asset[]): Promise<void> {
  const { bundlePath } = getConfig();

  const moveMultipleAssets = uploadedAssets.map((asset) => {
    const destinationAssetFilePath = path.join(bundlePath, asset.filename);
    return fsExtra.move(asset.file, destinationAssetFilePath, { overwrite: true });
  });
  await Promise.all(moveMultipleAssets);
  log.info(`Moved assets ${JSON.stringify(uploadedAssets.map((fileDescriptor) => fileDescriptor.filename))}`);
}
