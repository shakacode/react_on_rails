'use client';

import React from 'react';
import { ErrorBoundary as ErrorBoundaryLib } from 'react-error-boundary';
import ErrorComponent from './ErrorComponent';

export const ErrorBoundary = ({ children }: { children: React.ReactNode }) => {
  return <ErrorBoundaryLib FallbackComponent={ErrorComponent}>{children}</ErrorBoundaryLib>;
};

export default ErrorBoundary;
