/* eslint-disable no-unused-vars */
import React from 'react';

// Example of logging and throw error handling

const HelloWorldWithLogAndThrow = (props, context) => {
  console.log('console.log in HelloWorld');
  console.warn('console.warn in HelloWorld');
  console.error('console.error in HelloWorld');
  throw new Error('throw in HelloWorldContainer');
};

export default HelloWorldWithLogAndThrow;
