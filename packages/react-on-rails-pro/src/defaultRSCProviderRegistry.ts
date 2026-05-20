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

import type { ReactElement } from 'react';
import type { RailsContext } from 'react-on-rails/types';

type DefaultRSCProviderFactory = ({
  reactElement,
  railsContext,
  domNodeId,
}: {
  reactElement: ReactElement;
  railsContext: RailsContext;
  domNodeId: string;
}) => ReactElement;

let defaultRSCProviderFactory: DefaultRSCProviderFactory | undefined;

export const setDefaultRSCProviderFactory = (factory: DefaultRSCProviderFactory) => {
  defaultRSCProviderFactory = factory;
};

/** @internal Exported only for tests */
export const clearDefaultRSCProviderFactory = () => {
  defaultRSCProviderFactory = undefined;
};

export const maybeWrapWithDefaultRSCProviderWithStatus = (
  reactElement: ReactElement,
  railsContext: RailsContext,
  domNodeId: string,
): { reactElement: ReactElement; wrappedByDefaultRSCProvider: boolean } => {
  if (!defaultRSCProviderFactory || !railsContext.rscPayloadGenerationUrlPath) {
    return { reactElement, wrappedByDefaultRSCProvider: false };
  }

  return {
    reactElement: defaultRSCProviderFactory({ reactElement, railsContext, domNodeId }),
    wrappedByDefaultRSCProvider: true,
  };
};
