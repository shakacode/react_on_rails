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
/// <reference types="react/experimental" />
'use client';
import { jsx as _jsx } from "react/jsx-runtime";
import { Component, use } from 'react';
import { useRSC } from "./RSCProvider.js";
import { ServerComponentFetchError } from "./ServerComponentFetchError.js";
/**
 * Error boundary component for RSCRoute that adds server component name and props to the error
 * So, the parent ErrorBoundary can refetch the server component
 */
class RSCRouteErrorBoundary extends Component {
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
    // use is available in React 18.3+
    const promiseResult = use(promise);
    // In case that an error happened during the rendering of the RSC payload before the rendering of the component itself starts
    // RSC bundle will return an error object serialized inside the RSC payload
    if (promiseResult instanceof Error) {
        throw promiseResult;
    }
    return promiseResult;
};
const RSCRoute = ({ componentName, componentProps }) => {
    const { getComponent } = useRSC();
    const componentPromise = getComponent(componentName, componentProps);
    return (_jsx(RSCRouteErrorBoundary, { componentName: componentName, componentProps: componentProps, children: _jsx(PromiseWrapper, { promise: componentPromise }) }));
};
export default RSCRoute;
//# sourceMappingURL=RSCRoute.js.map