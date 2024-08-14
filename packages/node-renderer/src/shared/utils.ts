import cluster from 'cluster';
import path from 'path';
import { MultipartFile } from '@fastify/multipart';
import { createWriteStream, ensureDir, move, MoveOptions } from 'fs-extra';
import { pipeline } from 'stream';
import { promisify } from 'util';
import errorReporter from './errorReporter';
import { getConfig } from './configBuilder';
import log from './log';

export const TRUNCATION_FILLER = '\n... TRUNCATED ...\n';

export function workerIdLabel() {
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition -- worker is nullable in the primary process
  return cluster?.worker?.id || 'NO WORKER ID';
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
 * @param renderingRequest The JavaScript code which threw an error
 * @param error The error that was thrown (typed as `unknown` to minimize casts in `catch`)
 * @param context Optional context to include in the error message
 */
export function formatExceptionMessage(renderingRequest: string, error: unknown, context?: string) {
  return `${context ? `\nContext:\n${context}\n` : ''}
JS code for rendering request was:
${smartTrim(renderingRequest)}
    
EXCEPTION MESSAGE:
${(error as Error).message || error}

STACK:
${(error as Error).stack}`;
}

// https://github.com/fastify/fastify-multipart?tab=readme-ov-file#usage
const pump = promisify(pipeline);

export async function saveMultipartFile(
  multipartFile: MultipartFile,
  destinationPath: string,
): Promise<void> {
  await ensureDir(path.dirname(destinationPath));
  return pump(multipartFile.file, createWriteStream(destinationPath));
}

export interface Asset {
  type: 'asset';
  savedFilePath: string;
  filename: string;
}

export function moveUploadedAsset(
  asset: Asset,
  destinationPath: string,
  options: MoveOptions = {},
): Promise<void> {
  return move(asset.savedFilePath, destinationPath, options);
}

export async function moveUploadedAssets(uploadedAssets: Asset[]): Promise<void> {
  const { bundlePath } = getConfig();

  const moveMultipleAssets = uploadedAssets.map((asset) => {
    const destinationAssetFilePath = path.join(bundlePath, asset.filename);
    return moveUploadedAsset(asset, destinationAssetFilePath, { overwrite: true });
  });
  await Promise.all(moveMultipleAssets);
  log.info(`Moved assets ${JSON.stringify(uploadedAssets.map((fileDescriptor) => fileDescriptor.filename))}`);
}
