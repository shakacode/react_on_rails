import ReactOnRails from './ReactOnRails.full.ts';
import streamServerRenderedReactComponent from './streamServerRenderedReactComponent.ts';
import { getRSCPayloadStream, getRSCPayloadStreams, clearRSCPayloadStreams } from './RSCPayloadGenerator.ts';

ReactOnRails.streamServerRenderedReactComponent = streamServerRenderedReactComponent;
ReactOnRails.getRSCPayloadStream = getRSCPayloadStream;
ReactOnRails.getRSCPayloadStreams = getRSCPayloadStreams;
ReactOnRails.clearRSCPayloadStreams = clearRSCPayloadStreams;

export * from './ReactOnRails.full.ts';
// eslint-disable-next-line no-restricted-exports -- see https://github.com/eslint/eslint/issues/15617
export { default } from './ReactOnRails.full.ts';
