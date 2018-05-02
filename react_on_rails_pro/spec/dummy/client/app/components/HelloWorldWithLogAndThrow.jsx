/* eslint-disable no-unused-vars */
import React from 'react';

// Example of logging and throw error handling

const HelloWorldWithLogAndThrow = (props, context) => {
  /* eslint-disable no-console */
  console.log('console.log in HelloWorld');
  console.warn('console.warn in HelloWorld');
  console.error('console.error in HelloWorld');
  throw new Error('throw in HelloWorldWithLogAndThrow');
};

export default HelloWorldWithLogAndThrow;
