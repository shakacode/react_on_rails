import cluster from 'cluster';

import { getConfig } from './configBuilder';

export const TRUNCATION_FILLER = '\n... TRUNCATED ...\n';

export function workerIdLabel() {
  const workerId = (cluster && cluster.worker && cluster.worker.id) || 'NO WORKER ID';
  return workerId;
}

// From https://stackoverflow.com/a/831583/1009332
export function smartTrim(value, maxLength = getConfig().maxDebugSnippetLength) {
  let string;
  if (!value) return value;

  if (typeof value === 'string' || value instanceof String) {
    string = value;
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

export function errorResponseResult(msg) {
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
export function formatExceptionMessage(renderingRequest, error, context) {
  const exceptionMessage = `${context ? `\nContext:\n${context}\n` : ''}
JS code for rendering request was:
${smartTrim(renderingRequest)}
    
EXCEPTION MESSAGE:
${error.message || error}

STACK:
${error.stack}`;

  return exceptionMessage;
}
