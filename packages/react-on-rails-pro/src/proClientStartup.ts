/* eslint-disable import/prefer-default-export -- named export for consistency with capability API */

/*
 * Copyright (c) 2025 Shakacode LLC
 *
 * This file is NOT licensed under the MIT (open source) license.
 * It is part of the React on Rails Pro offering and is licensed separately.
 *
 * Unauthorized copying, modification, distribution, or use of this file,
 * via any medium, is strictly prohibited without a valid license agreement
 * from Shakacode LLC.
 *
 * For licensing terms, please see:
 * https://github.com/shakacode/react_on_rails/blob/master/REACT-ON-RAILS-PRO-LICENSE.md
 */

import { getRailsContext } from 'react-on-rails/context';
import { onPageLoaded, onPageUnloaded } from 'react-on-rails/pageLifecycle';
import { debugTurbolinks } from 'react-on-rails/turbolinksUtils';
import {
  renderOrHydrateCompleteComponents,
  hydrateCompleteStores,
  unmountAll,
} from './ClientSideRenderer.ts';
import { reactOnRailsPageLoaded } from './capabilities/proLifecycle.ts';

function reactOnRailsPageUnloaded(): void {
  debugTurbolinks('reactOnRailsPageUnloaded [PRO]');
  unmountAll();
}

export function proClientStartup() {
  if (globalThis.document === undefined) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle
  if (globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__) {
    return;
  }

  // eslint-disable-next-line no-underscore-dangle
  globalThis.__REACT_ON_RAILS_EVENT_HANDLERS_RAN_ONCE__ = true;

  const railsContext = getRailsContext();
  if (railsContext === null) {
    // Context element not yet in DOM — expected in streaming scenarios.
    // Early Pro hydration skipped; the page-loaded sweep will recover all components.
    if (process.env.NODE_ENV !== 'production' && typeof console !== 'undefined') {
      console.debug(
        '[React on Rails] railsContext not available at clientStartup — early Pro hydration skipped, falling back to page-load sweep.',
      );
    }
  } else if (railsContext.rorPro) {
    // Streaming pages can trigger these incrementally as markup arrives. The later
    // page-loaded sweep is safe because ClientSideRenderer memoizes by DOM/store id.
    void renderOrHydrateCompleteComponents();
    void hydrateCompleteStores();
  }

  onPageLoaded(reactOnRailsPageLoaded);
  onPageUnloaded(reactOnRailsPageUnloaded);
}
