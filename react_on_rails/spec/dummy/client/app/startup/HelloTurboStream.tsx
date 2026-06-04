import React from 'react';
import RailsContext, { type RailsContextForDisplay } from '../components/RailsContext';

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
