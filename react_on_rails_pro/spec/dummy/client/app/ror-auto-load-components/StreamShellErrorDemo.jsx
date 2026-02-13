import React from 'react';

const StreamShellErrorDemo = () => {
  throw new Error('Component crashed immediately during shell render!');

  return <div>This will never render</div>;
};

export default StreamShellErrorDemo;
