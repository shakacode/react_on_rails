import ReactOnRails from './ReactOnRails.full.ts';

// Pro-only functionality - provide stub that directs users to upgrade

ReactOnRails.streamServerRenderedReactComponent = () => {
  throw new Error('streamServerRenderedReactComponent requires react-on-rails-pro package');
};

export * from './ReactOnRails.full.ts';
// eslint-disable-next-line no-restricted-exports -- see https://github.com/eslint/eslint/issues/15617
export { default } from './ReactOnRails.full.ts';
