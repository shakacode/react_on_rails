import ReactOnRails from './ReactOnRails.full.ts';
import streamServerRenderedReactComponent from './streamServerRenderedReactComponent.ts';
import {
  getRSCPayloadStream,
  getRSCPayloadStreams,
  clearRSCPayloadStreams,
  onRSCPayloadGenerated,
} from './RSCPayloadGenerator.ts';
import { addPostSSRHook } from './postSSRHooks.ts';

ReactOnRails.streamServerRenderedReactComponent = streamServerRenderedReactComponent;
ReactOnRails.getRSCPayloadStream = getRSCPayloadStream;
ReactOnRails.getRSCPayloadStreams = getRSCPayloadStreams;
ReactOnRails.clearRSCPayloadStreams = clearRSCPayloadStreams;
ReactOnRails.onRSCPayloadGenerated = onRSCPayloadGenerated;
ReactOnRails.addPostSSRHook = addPostSSRHook;

export * from './ReactOnRails.full.ts';
// eslint-disable-next-line no-restricted-exports -- see https://github.com/eslint/eslint/issues/15617
export { default } from './ReactOnRails.full.ts';
