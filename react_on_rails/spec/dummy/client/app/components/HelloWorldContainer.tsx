import React from 'react';
import { connect, type ConnectedProps } from 'react-redux';
import { bindActionCreators, type Dispatch } from 'redux';

import * as helloWorldActions from '../actions/HelloWorldActions';
import type { HelloWorldNameUpdateAction } from '../actions/HelloWorldActions';
import type { ReduxAppState } from '../store/reduxTypes';
import HelloWorldRedux from './HelloWorldRedux';

const mapStateToProps = (state: ReduxAppState) => ({
  data: state.helloWorldData,
  railsContext: state.railsContext,
});

const mapDispatchToProps = (dispatch: Dispatch<HelloWorldNameUpdateAction>) => ({
  actions: bindActionCreators(helloWorldActions, dispatch),
});

const connector = connect(mapStateToProps, mapDispatchToProps);

type PropsFromRedux = ConnectedProps<typeof connector>;

const HelloWorldContainer = ({ actions, data, railsContext }: PropsFromRedux) => (
  <HelloWorldRedux actions={actions} data={data} railsContext={railsContext} />
);

export type { PropsFromRedux as HelloWorldContainerProps };
export default connector(HelloWorldContainer);
