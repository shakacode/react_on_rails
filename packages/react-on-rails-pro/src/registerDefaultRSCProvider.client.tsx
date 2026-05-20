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

'use client';

import * as React from 'react';
import { createRSCProvider } from './RSCProvider.tsx';
import { setDefaultRSCProviderFactory } from './defaultRSCProviderRegistry.ts';

if (typeof window !== 'undefined') {
  setDefaultRSCProviderFactory(({ reactElement, railsContext, domNodeId }) => {
    const RSCProvider = createRSCProvider({
      getServerComponent: async (args) => {
        const { default: getReactServerComponent } = await import('./getReactServerComponent.client.ts');
        return getReactServerComponent(domNodeId, railsContext)(args);
      },
    });

    return <RSCProvider>{reactElement}</RSCProvider>;
  });
}
