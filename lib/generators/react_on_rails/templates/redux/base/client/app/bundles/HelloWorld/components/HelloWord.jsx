import React, { PropTypes } from 'react';

const HelloWorld = ({name, onNameUpdate}) => {
  return (
    <div>
      <h3>
        Hello, {name}!
      </h3>
      <hr />
      <form >
        <label htmlFor="name">
          Say hello to:
        </label>
        <input
          id="name"
          type="text"
          value={name}
          onChange={(e) => onNameUpdate(e.target.value)}
          />
      </form>
    </div>
  )
}

HelloWorld.propTypes = {
  name: PropTypes.string.isRequired,
  onNameUpdate: PropTypes.func.isRequired
}

export default HelloWorld;
