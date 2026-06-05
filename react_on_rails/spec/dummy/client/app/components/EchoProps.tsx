import React from 'react';

type EchoPropsProps = Record<string, unknown>;

const EchoProps = (props: EchoPropsProps) => <div>Props: {JSON.stringify(props)}</div>;

export type { EchoPropsProps };
export default EchoProps;
