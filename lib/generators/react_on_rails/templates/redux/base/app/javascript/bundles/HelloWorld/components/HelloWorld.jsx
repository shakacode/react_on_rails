import PropTypes from 'prop-types';
import React from 'react';
import * as style from './HelloWorld.module.css';

const HelloWorld = ({ name, updateName }) => (
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

HelloWorld.propTypes = {
  name: PropTypes.string.isRequired,
  updateName: PropTypes.func.isRequired,
};

export default HelloWorld;
