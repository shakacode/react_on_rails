import cluster from 'cluster';
import path from 'path';
import { MultipartFile } from '@fastify/multipart';
import { createWriteStream, ensureDir, move, MoveOptions, copy, CopyOptions, unlink } from 'fs-extra';
import { Readable, pipeline, PassThrough } from 'stream';
import { promisify } from 'util';
import * as errorReporter from './errorReporter.js';
import { getConfig } from './configBuilder.js';
import log from './log.js';
import type { RenderResult } from '../worker/vm.js';
import fileExistsAsync from './fileExistsAsync.js';

export const TRUNCATION_FILLER = '\n... TRUNCATED ...\n';

export const SHUTDOWN_WORKER_MESSAGE = 'NODE_RENDERER_SHUTDOWN_WORKER';

export function workerIdLabel() {
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
  stream?: Readable;
}

export function errorResponseResult(msg: string): ResponseResult {
  errorReporter.message(msg);
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

export function copyUploadedAsset(
  asset: Asset,
  destinationPath: string,
  options: CopyOptions = {},
): Promise<void> {
  return copy(asset.savedFilePath, destinationPath, options);
}

export async function copyUploadedAssets(uploadedAssets: Asset[], targetDirectory: string): Promise<void> {
  const copyMultipleAssets = uploadedAssets.map((asset) => {
    const destinationAssetFilePath = path.join(targetDirectory, asset.filename);
    return copyUploadedAsset(asset, destinationAssetFilePath, { overwrite: true });
  });
  await Promise.all(copyMultipleAssets);
  log.info(
    `Copied assets ${JSON.stringify(uploadedAssets.map((fileDescriptor) => fileDescriptor.filename))}`,
  );
}

export async function deleteUploadedAssets(uploadedAssets: Asset[]): Promise<void> {
  const deleteMultipleAssets = uploadedAssets.map((asset) => unlink(asset.savedFilePath));
  await Promise.all(deleteMultipleAssets);
  log.info(
    `Deleted assets ${JSON.stringify(uploadedAssets.map((fileDescriptor) => fileDescriptor.filename))}`,
  );
}

export function isPromise<T>(value: T | Promise<T>): value is Promise<T> {
  return value && typeof (value as Promise<T>).then === 'function';
}

export const isReadableStream = (stream: unknown): stream is Readable =>
  typeof stream === 'object' &&
  stream !== null &&
  typeof (stream as Readable).pipe === 'function' &&
  typeof (stream as Readable).read === 'function';

export const handleStreamError = (stream: Readable, onError: (error: Error) => void) => {
  const newStreamAfterHandlingError = new PassThrough();

  stream.on('error', onError);

  stream.pipe(newStreamAfterHandlingError);
  return newStreamAfterHandlingError;
};

export const isErrorRenderResult = (result: RenderResult): result is { exceptionMessage: string } =>
  typeof result === 'object' && !isReadableStream(result) && 'exceptionMessage' in result;

// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
export const majorVersion = (version: string) => Number.parseInt(version.split('.', 2)[0]!, 10);

// Can be replaced by `import { setTimeout } from 'timers/promises'` when Node 16 is the minimum supported version
export const delay = (milliseconds: number) =>
  new Promise((resolve) => {
    setTimeout(resolve, milliseconds);
  });

export function getBundleDirectory(bundleTimestamp: string | number) {
  const { serverBundleCachePath } = getConfig();
  return path.join(serverBundleCachePath, `${bundleTimestamp}`);
}

export function getRequestBundleFilePath(bundleTimestamp: string | number) {
  const bundleDirectory = getBundleDirectory(bundleTimestamp);
  return path.join(bundleDirectory, `${bundleTimestamp}.js`);
}

export function getAssetPath(bundleTimestamp: string | number, filename: string) {
  const bundleDirectory = getBundleDirectory(bundleTimestamp);
  return path.join(bundleDirectory, filename);
}

export async function validateBundlesExist(
  bundleTimestamp: string | number,
  dependencyBundleTimestamps?: (string | number)[],
): Promise<ResponseResult | null> {
  const missingBundles = (
    await Promise.all(
      [...(dependencyBundleTimestamps ?? []), bundleTimestamp].map(async (timestamp) => {
        const bundleFilePath = getRequestBundleFilePath(timestamp);
        const fileExists = await fileExistsAsync(bundleFilePath);
        return fileExists ? null : timestamp;
      }),
    )
  ).filter((timestamp) => timestamp !== null);

  if (missingBundles.length > 0) {
    const missingBundlesText = missingBundles.length > 1 ? 'bundles' : 'bundle';
    log.info(`No saved ${missingBundlesText}: ${missingBundles.join(', ')}`);
    return {
      headers: { 'Cache-Control': 'no-cache, no-store, max-age=0, must-revalidate' },
      status: 410,
      data: 'No bundle uploaded',
    };
  }
  return null;
}
