import React from 'react';
import RailsContext from '../components/RailsContext';
import type { RailsContextForDisplay } from '../types/railsContext';

import css from '../components/HelloWorld.module.scss';

type HelloTurboStreamData = Record<string, unknown> & {
  name: string;
};

type HelloTurboStreamProps = {
  helloTurboStreamData: HelloTurboStreamData;
  railsContext?: RailsContextForDisplay;
};

const HelloTurboStream = ({ helloTurboStreamData, railsContext }: HelloTurboStreamProps) => (
  <div>
    <h3 className={css.brightColor}>Hello, {helloTurboStreamData.name}!</h3>
    {railsContext && <RailsContext railsContext={railsContext} />}
  </div>
);

export default HelloTurboStream;
