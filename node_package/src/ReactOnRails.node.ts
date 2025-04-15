import ReactOnRails from './ReactOnRails.full';
import streamServerRenderedReactComponent from './streamServerRenderedReactComponent';
import { getRSCPayloadStream, getRSCPayloadStreams, clearRSCPayloadStreams } from './RSCPayloadGenerator';

ReactOnRails.streamServerRenderedReactComponent = streamServerRenderedReactComponent;
ReactOnRails.getRSCPayloadStream = getRSCPayloadStream;
ReactOnRails.getRSCPayloadStreams = getRSCPayloadStreams;
ReactOnRails.clearRSCPayloadStreams = clearRSCPayloadStreams;

export * from './ReactOnRails.full';
// eslint-disable-next-line no-restricted-exports -- see https://github.com/eslint/eslint/issues/15617
export { default } from './ReactOnRails.full';
