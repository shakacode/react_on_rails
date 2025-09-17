import React from 'react';
import * as style from './HelloWorld.module.css';

interface HelloWorldProps {
  name: string;
  updateName: (name: string) => void;
}

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
        <input
          id="name"
          type="text"
          value={name}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) => updateName(e.target.value)}
        />
      </label>
    </form>
  </div>
);

export default HelloWorld;