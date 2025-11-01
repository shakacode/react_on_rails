import { jsx as _jsx } from 'react/jsx-runtime';
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
import * as React from 'react';
import { useRSC } from './RSCProvider.js';
import { ServerComponentFetchError } from './ServerComponentFetchError.js';
/**
 * Error boundary component for RSCRoute that adds server component name and props to the error
 * So, the parent ErrorBoundary can refetch the server component
 */
class RSCRouteErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  render() {
    const { error } = this.state;
    const { componentName, componentProps, children } = this.props;
    if (error) {
      throw new ServerComponentFetchError(error.message, componentName, componentProps, error);
    }
    return children;
  }
}
const PromiseWrapper = ({ promise }) => {
  return React.use(promise);
};
const RSCRoute = ({ componentName, componentProps }) => {
  const { getComponent } = useRSC();
  const componentPromise = getComponent(componentName, componentProps);
  return _jsx(RSCRouteErrorBoundary, {
    componentName,
    componentProps,
    children: _jsx(PromiseWrapper, { promise: componentPromise }),
  });
};
export default RSCRoute;
