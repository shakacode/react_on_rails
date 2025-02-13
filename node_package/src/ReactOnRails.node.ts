import ReactOnRails from './ReactOnRails';
import streamServerRenderedReactComponent from './streamServerRenderedReactComponent';
import RSCServerRoot from './RSCServerRoot';

ReactOnRails.streamServerRenderedReactComponent = streamServerRenderedReactComponent;
// @ts-expect-error eeee
ReactOnRails.RSCServerRoot = RSCServerRoot;

export * from './ReactOnRails';
export { default } from './ReactOnRails';
