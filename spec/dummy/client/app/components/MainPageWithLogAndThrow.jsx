/* eslint-disable no-unused-vars */
import React from 'react';

// Example of logging and throw error handling

const MainPageWithLogAndThrow = (props, context) => {
  /* eslint-disable no-console */
  console.log('console.log in MainPage');
  console.warn('console.warn in MainPage');
  console.error('console.error in MainPage');
  throw new Error('throw in MainPageContainer');
};

export default MainPageWithLogAndThrow;
