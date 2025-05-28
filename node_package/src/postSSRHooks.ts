import { RailsContextWithServerComponentCapabilities } from './types/index.ts';

type PostSSRHook = () => void;
const postSSRHooks = new Map<string, PostSSRHook[]>();

export const addPostSSRHook = (
  railsContext: RailsContextWithServerComponentCapabilities,
  hook: PostSSRHook,
) => {
  const hooks = postSSRHooks.get(railsContext.componentSpecificMetadata.renderRequestId);
  if (hooks) {
    hooks.push(hook);
  } else {
    postSSRHooks.set(railsContext.componentSpecificMetadata.renderRequestId, [hook]);
  }
};

export const notifySSREnd = (railsContext: RailsContextWithServerComponentCapabilities) => {
  const hooks = postSSRHooks.get(railsContext.componentSpecificMetadata.renderRequestId);
  if (hooks) {
    hooks.forEach((hook) => hook());
  }
  postSSRHooks.delete(railsContext.componentSpecificMetadata.renderRequestId);
};
