/**
 * Render a single component by its DOM ID.
 * This is the main entry point for rendering individual components.
 */
export declare function renderComponent(domId: string): void;
/**
 * Render all stores on the page.
 */
export declare function renderAllStores(): void;
/**
 * Render all components on the page.
 * Core package renders all components after page load.
 */
export declare function renderAllComponents(): void;
/**
 * Public API function that can be called to render a component after it has been loaded.
 * This is the function that should be exported and used by the Rails integration.
 * Returns a Promise for API compatibility with pro version.
 */
export declare function reactOnRailsComponentLoaded(domId: string): Promise<void>;
//# sourceMappingURL=ClientRenderer.d.ts.map
