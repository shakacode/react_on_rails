'use client';

// Example of logging and throw error handling

const HelloWorldWithLogAndThrow = (_props, _context) => {
  console.log('console.log in HelloWorld');
  console.warn('console.warn in HelloWorld');
  console.error('console.error in HelloWorld');
  throw new Error('throw in HelloWorldWithLogAndThrow');
};

export default HelloWorldWithLogAndThrow;
