import cluster from 'cluster';
import type { ResponseResult } from '../shared/utils';
import { buildVM, runInVM } from './vm';
import { getRequestBundleFilePath, validateBundlesExist, errorResponseResult, formatExceptionMessage } from '../shared/utils';
import * as errorReporter from '../shared/errorReporter';

export interface BundleValidationResult {
  success: boolean;
  error?: ResponseResult;
  bundleFilePath?: string;
  dependencyBundleFilePaths?: string[];
}

export interface VMBuildResult {
  success: boolean;
  error?: ResponseResult;
}

export interface RenderExecutionResult {
  success: boolean;
  result?: ResponseResult;
  error?: ResponseResult;
}

/**
 * Validates bundles and returns bundle file paths
 */
export async function validateAndGetBundlePaths(
  bundleTimestamp: string | number,
  dependencyBundleTimestamps?: Array<string | number>,
): Promise<BundleValidationResult> {
  try {
    // Check if the bundle exists
    const missingBundleError = await validateBundlesExist(bundleTimestamp, dependencyBundleTimestamps);
    if (missingBundleError) {
      return {
        success: false,
        error: missingBundleError,
      };
    }

    // Get bundle file paths
    const bundleFilePath = getRequestBundleFilePath(bundleTimestamp);
    const dependencyBundleFilePaths = dependencyBundleTimestamps?.map(getRequestBundleFilePath) || [];

    return {
      success: true,
      bundleFilePath,
      dependencyBundleFilePaths,
    };
  } catch (error) {
    const errorMessage = formatExceptionMessage(
      'Bundle validation',
      error,
      'Error during bundle validation',
    );
    return {
      success: false,
      error: errorResponseResult(errorMessage),
    };
  }
}

/**
 * Builds VMs for the main bundle and dependencies
 */
export async function buildVMsForBundles(
  bundleFilePath: string,
  dependencyBundleFilePaths: string[],
): Promise<VMBuildResult> {
  try {
    // Build main VM
    await buildVM(bundleFilePath);

    // Build dependency VMs if they exist
    if (dependencyBundleFilePaths.length > 0) {
      await Promise.all(dependencyBundleFilePaths.map(buildVM));
    }

    return { success: true };
  } catch (error) {
    const errorMessage = formatExceptionMessage(
      'VM building',
      error,
      'Error building VMs for bundles',
    );
    return {
      success: false,
      error: errorResponseResult(errorMessage),
    };
  }
}

/**
 * Executes rendering in VM with optional EventEmitter for incremental rendering
 */
export async function executeRenderInVM(
  renderingRequest: string,
  bundleFilePath: string,
  updateEmitter?: any, // EventEmitter for incremental rendering
): Promise<RenderExecutionResult> {
  try {
    const renderResult = await runInVM(renderingRequest, bundleFilePath, cluster, updateEmitter);

    if (typeof renderResult === 'string') {
      // Render completed successfully
      return {
        success: true,
        result: {
          status: 200,
          headers: { 'Cache-Control': 'public, max-age=31536000' },
          data: renderResult,
        },
      };
    } else if (renderResult && 'exceptionMessage' in renderResult) {
      // Render failed
      return {
        success: false,
        error: errorResponseResult(renderResult.exceptionMessage),
      };
    } else if (renderResult && typeof renderResult === 'object' && 'stream' in renderResult) {
      // Stream result
      return {
        success: true,
        result: {
          status: 200,
          headers: { 'Cache-Control': 'public, max-age=31536000' },
          stream: renderResult.stream,
        } as ResponseResult,
      };
    }

    // Unknown result type
    return {
      success: false,
      error: errorResponseResult('Unknown render result type'),
    };
  } catch (error) {
    const errorMessage = formatExceptionMessage(
      renderingRequest,
      error,
      'Error executing render in VM',
    );
    return {
      success: false,
      error: errorResponseResult(errorMessage),
    };
  }
}

/**
 * Creates a standard error response for render failures
 */
export function createRenderErrorResponse(
  renderingRequest: string,
  error: unknown,
  context: string,
): ResponseResult {
  const errorMessage = formatExceptionMessage(renderingRequest, error, context);
  errorReporter.message(errorMessage);
  return errorResponseResult(errorMessage);
}
