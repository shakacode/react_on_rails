import React from 'react';

function allObjectKeys(obj) {
  const result = [];
  /* eslint-disable guard-for-in */
  for (const prop in obj) {
    result.push(prop);
  }

  return result;
}

function arrIncludes(arr, value) {
  return (arr.indexOf(value) > -1);
}

export default function generatorFunction(component) {
  const prototypeKeys = allObjectKeys(component.prototype);
  const keys = allObjectKeys(component);

  // es5 React Component
  if (arrIncludes(prototypeKeys, 'constructor') && arrIncludes(prototypeKeys, 'render')) {
    return false;
  } else if (arrIncludes(prototypeKeys, 'isReactComponent')  // es6 React Component
    || arrIncludes(keys, 'propTypes')
    || component.prototype instanceof React.Component) {
    return false;
  }

  // Else, we assume a generator function!
  return true;
}
