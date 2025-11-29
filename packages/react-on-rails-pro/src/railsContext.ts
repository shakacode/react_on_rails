import type { RailsContext } from 'react-on-rails/types';
import { getRailsContext as getRailsContextCore } from 'react-on-rails/context';

export type RailsContextPro = RailsContext & {
  rorPro: true;
};

export * from 'react-on-rails/context';

function assertRailsContextPro(context: RailsContext): asserts context is RailsContextPro {
  if (!context.rorPro) {
    throw new Error(
      "react-on-rails-pro package can't be used with the core react_on_rails gem. " +
        'Please upgrade to react_on_rails_pro gem' +
        'Please visit https://shakacode.com/react-on-rails-pro to get a license.',
    );
  }
}

export function getRailsContext(): RailsContextPro | null {
  const railsContextCore = getRailsContextCore();
  if (railsContextCore) {
    assertRailsContextPro(railsContextCore);
  }

  return railsContextCore;
}
