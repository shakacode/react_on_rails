import React from 'react';
import * as style from './HelloWorld.module.css';
import type { PropsFromRedux } from '../containers/HelloWorldContainer';

// Component props are inferred from Redux container
type HelloWorldProps = PropsFromRedux;

const HelloWorld: React.FC<HelloWorldProps> = ({ name, updateName }) => (
  <div>
    <h3>
      Hello,
      {name}!
    </h3>
    <hr />
    <form>
      <label className={style.bright} htmlFor="name">
        Say hello to:
        <input id="name" type="text" value={name} onChange={(e) => updateName(e.target.value)} />
      </label>
    </form>
  </div>
);

export default HelloWorld;
