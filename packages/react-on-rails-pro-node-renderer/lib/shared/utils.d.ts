import { MultipartFile } from '@fastify/multipart';
import { MoveOptions, CopyOptions } from 'fs-extra';
import { Readable, PassThrough } from 'stream';
import type { RenderResult } from '../worker/vm.js';
export declare const TRUNCATION_FILLER = "\n... TRUNCATED ...\n";
export declare const SHUTDOWN_WORKER_MESSAGE = "NODE_RENDERER_SHUTDOWN_WORKER";
export declare function workerIdLabel(): number | "NO WORKER ID";
export declare function smartTrim(value: unknown, maxLength?: number): string | null;
export interface ResponseResult {
    headers: {
        'Cache-Control'?: string;
    };
    status: number;
    data?: unknown;
    stream?: Readable;
}
export declare function errorResponseResult(msg: string): ResponseResult;
/**
 * @param renderingRequest The JavaScript code which threw an error
 * @param error The error that was thrown (typed as `unknown` to minimize casts in `catch`)
 * @param context Optional context to include in the error message
 */
export declare function formatExceptionMessage(renderingRequest: string, error: unknown, context?: string): string;
export declare function saveMultipartFile(multipartFile: MultipartFile, destinationPath: string): Promise<void>;
export interface Asset {
    type: 'asset';
    savedFilePath: string;
    filename: string;
}
export declare function moveUploadedAsset(asset: Asset, destinationPath: string, options?: MoveOptions): Promise<void>;
export declare function copyUploadedAsset(asset: Asset, destinationPath: string, options?: CopyOptions): Promise<void>;
export declare function copyUploadedAssets(uploadedAssets: Asset[], targetDirectory: string): Promise<void>;
export declare function isPromise<T>(value: T | Promise<T>): value is Promise<T>;
export declare const isReadableStream: (stream: unknown) => stream is Readable;
export declare const handleStreamError: (stream: Readable, onError: (error: Error) => void) => PassThrough;
export declare const isErrorRenderResult: (result: RenderResult) => result is {
    exceptionMessage: string;
};
export declare const majorVersion: (version: string) => number;
export declare const delay: (milliseconds: number) => Promise<unknown>;
export declare function getBundleDirectory(bundleTimestamp: string | number): string;
export declare function getRequestBundleFilePath(bundleTimestamp: string | number): string;
export declare function getAssetPath(bundleTimestamp: string | number, filename: string): string;
export declare function validateBundlesExist(bundleTimestamp: string | number, dependencyBundleTimestamps?: (string | number)[]): Promise<ResponseResult | null>;
//# sourceMappingURL=utils.d.ts.map