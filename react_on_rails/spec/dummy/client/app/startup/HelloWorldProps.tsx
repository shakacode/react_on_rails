import React, { useEffect, useState } from 'react';

import css from '../components/HelloWorld.module.scss';

import type { HelloWorldData } from './HelloWorld';

type Props = {
  helloWorldData: HelloWorldData;
  modificationTarget: string;
};

function HelloWorldProps({ helloWorldData, modificationTarget }: Props) {
  console.log(`HelloWorldProps modification target prop value: ${modificationTarget}`);

  const [name, setName] = useState(helloWorldData.name);
  // a trick to display a client-only prop value without creating a server/client conflict
  const [delayedValue, setDelayedValue] = useState<string | null>(null);

  useEffect(() => {
    setDelayedValue(modificationTarget);
  }, [modificationTarget]);

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
      <h4>Value of modification target prop: {delayedValue}</h4>
    </div>
  );
}

export type { Props as HelloWorldPropsProps };
export default HelloWorldProps;
