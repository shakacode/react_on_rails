import type { RailsContext } from 'react-on-rails/types';

type RailsContextForDisplay = RailsContext & Record<string, unknown>;

// eslint-disable-next-line import/prefer-default-export -- shared display type for dummy app context consumers
export type { RailsContextForDisplay };
