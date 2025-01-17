import ReactOnRails from './ReactOnRails';
import { setReactOnRails } from './context';
import streamServerRenderedReactComponent from './streamServerRenderedReactComponent';

ReactOnRails.streamServerRenderedReactComponent = streamServerRenderedReactComponent;

setReactOnRails(ReactOnRails);

export default ReactOnRails;
export * from './types';
