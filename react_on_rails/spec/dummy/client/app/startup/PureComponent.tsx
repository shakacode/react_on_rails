import React from 'react';

type PureComponentProps = {
  title: string;
};

const PureComponent = ({ title }: PureComponentProps) => <h1>{title}</h1>;

export default PureComponent;
