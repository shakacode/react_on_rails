import { createBaseClientObject } from "./client.js";
import handleError from "../handleError.js";
import serverRenderReactComponent from "../serverRenderReactComponent.js";
// Warn about bundle size when included in browser bundles
if (typeof window !== 'undefined') {
    console.warn('Optimization opportunity: "react-on-rails" includes ~14KB of server-rendering code. ' +
        'Browsers may not need it. See https://forum.shakacode.com/t/how-to-use-different-versions-of-a-file-for-client-and-server-rendering/1352 ' +
        '(Requires creating a free account). Click this for the stack trace.');
}
export function createBaseFullObject(registries, currentObject = null) {
    // Get or create client object (with caching logic)
    const clientObject = createBaseClientObject(registries, currentObject);
    // Define SSR-specific functions with proper types
    // This object acts as a type-safe specification of what we're adding to the base object
    const reactOnRailsFullSpecificFunctions = {
        handleError(options) {
            return handleError(options);
        },
        serverRenderReactComponent(options) {
            return serverRenderReactComponent(options);
        },
    };
    // Type assertion is safe here because:
    // 1. We start with BaseClientObjectType (from createBaseClientObject)
    // 2. We add exactly the methods defined in ReactOnRailsFullSpecificFunctions
    // 3. BaseFullObjectType = BaseClientObjectType + ReactOnRailsFullSpecificFunctions
    // TypeScript can't track the mutation, but we ensure type safety by explicitly typing
    // the functions object above
    const fullObject = clientObject;
    // Assign SSR-specific functions to the full object using Object.assign
    // This pattern ensures we add exactly what's defined in the type, nothing more, nothing less
    Object.assign(fullObject, reactOnRailsFullSpecificFunctions);
    return fullObject;
}
//# sourceMappingURL=full.js.map