import React from 'react';

type PureComponentWrappedInFunctionProps = {
  title?: string;
};

// The extra function wrapper is unnecessary here
const PureComponentWrappedInFunction =
  ({ title }: PureComponentWrappedInFunctionProps) =>
  () => <h1>{title}</h1>;

export default PureComponentWrappedInFunction;
