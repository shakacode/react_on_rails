import { RailsContextWithComponentSpecificMetadata } from './types/index.ts';

// Override the fetch function to make it easier to test
// The default fetch implementation in jest returns Node's Readable stream
// In jest.setup.js, we configure this fetch to return a web-standard ReadableStream instead,
// which matches browser behavior where fetch responses have ReadableStream bodies
// See jest.setup.js for the implementation details
const customFetch = (...args: Parameters<typeof fetch>) => {
  const res = fetch(...args);
  return res;
};

export { customFetch as fetch };

export const createRSCPayloadKey = (
  componentName: string,
  componentProps: unknown,
  railsContext: RailsContextWithComponentSpecificMetadata,
) => {
  return `${componentName}-${JSON.stringify(componentProps)}-${railsContext.componentSpecificMetadata.renderRequestId}`;
};
