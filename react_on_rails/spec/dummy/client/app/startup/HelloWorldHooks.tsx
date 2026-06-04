// Super simple example of the simplest possible React component
import React, { useState } from 'react';

import css from '../components/HelloWorld.module.scss';

import type { HelloWorldData } from './HelloWorld';

type HelloWorldHooksProps = {
  helloWorldData: HelloWorldData;
};

// TODO: make more like the HelloWorld.tsx
function HelloWorldHooks({ helloWorldData }: HelloWorldHooksProps) {
  const [name, setName] = useState(helloWorldData.name);
  return (
    <div>
      <h3 className={css.brightColor}>Hello, {name}!</h3>
      <p>
        Say hello to:
        <input
          type="text"
          value={name}
          onChange={(event: React.ChangeEvent<HTMLInputElement>) => setName(event.currentTarget.value)}
        />
      </p>
    </div>
  );
}

export type { HelloWorldHooksProps };
export default HelloWorldHooks;
