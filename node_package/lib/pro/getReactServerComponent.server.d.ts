import type { RailsContextWithServerStreamingCapabilities } from '../types/index.ts';

type GetReactServerComponentOnServerProps = {
  componentName: string;
  componentProps: unknown;
};
/**
 * Creates a function that fetches and renders a server component on the server side.
 *
 * This style of higher-order function is necessary as the function that gets server components
 * on server has different parameters than the function that gets them on client. The environment
 * dependent parameters (railsContext) are passed from the `wrapServerComponentRenderer`
 * function, while the environment agnostic parameters (componentName, componentProps) are
 * passed from the RSCProvider which is environment agnostic.
 *
 * The returned function:
 * 1. Validates the railsContext for required properties
 * 2. Creates an SSR manifest mapping server and client modules
 * 3. Gets the RSC payload stream via getRSCPayloadStream
 * 4. Processes the stream with React's SSR runtime
 *
 * During SSR, this function ensures that the RSC payload is both:
 * - Used to render the server component
 * - Tracked so it can be embedded in the HTML response
 *
 * @param railsContext - Context for the current request with server streaming capabilities
 * @returns A function that accepts RSC parameters and returns a Promise resolving to the rendered React element
 *
 * The returned function accepts:
 * @param componentName - Name of the server component to render
 * @param componentProps - Props to pass to the server component
 *
 * @important This is an internal function. End users should not use this directly.
 * Instead, use the useRSC hook which provides getComponent and refetchComponent functions
 * for fetching or retrieving cached server components. For rendering server components,
 * consider using RSCRoute component which handles the rendering logic automatically.
 */
declare const getReactServerComponent: (
  railsContext: RailsContextWithServerStreamingCapabilities,
) => ({
  componentName,
  componentProps,
}: GetReactServerComponentOnServerProps) => Promise<
  | bigint
  | import('react').ReactElement<any, string | import('react').JSXElementConstructor<any>>
  | Iterable<import('react').ReactNode>
  | import('react').AwaitedReactNode
>;
export default getReactServerComponent;
