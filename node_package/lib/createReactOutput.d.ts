import type { CreateParams, CreateReactOutputResult } from './types/index';
/**
 * Logic to either call the renderFunction or call React.createElement to get the
 * React.Component
 * @param options
 * @param options.componentObj
 * @param options.props
 * @param options.domNodeId
 * @param options.trace
 * @param options.location
 * @returns {ReactElement}
 */
export default function createReactOutput({ componentObj, props, railsContext, domNodeId, trace, shouldHydrate, }: CreateParams): CreateReactOutputResult;
