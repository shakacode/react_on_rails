// Example of using hooks when taking the props and railsContext
// Note, you need the call the hooks API within the react component stateless function
import React, { useState } from 'react';

import css from '../components/HelloWorld.module.scss';
import RailsContext from '../components/RailsContext';
import type { RailsContextForDisplay } from '../types/railsContext';

import type { HelloWorldData } from './HelloWorld';

type HelloWorldHooksContextProps = {
  helloWorldData: HelloWorldData;
};

type HelloWorldHooksContextRenderFunction = (
  props: HelloWorldHooksContextProps,
  railsContext: RailsContextForDisplay,
) => React.ComponentType<Record<string, never>>;

// You could pass props here or use the closure
const HelloWorldHooksContext: HelloWorldHooksContextRenderFunction = ({ helloWorldData }, railsContext) => {
  const Result = () => {
    const [name, setName] = useState(helloWorldData.name);
    return (
      <>
        <h3 className={css.brightColor}>Hello, {name}!</h3>
        <p>
          Say hello to:
          <input
            type="text"
            value={name}
            onChange={(event: React.ChangeEvent<HTMLInputElement>) => setName(event.currentTarget.value)}
          />
        </p>
        <p>Rails Context :</p>
        <RailsContext railsContext={railsContext} />
      </>
    );
  };

  return Result;
};

export type { HelloWorldHooksContextProps, HelloWorldHooksContextRenderFunction };
export default HelloWorldHooksContext;
