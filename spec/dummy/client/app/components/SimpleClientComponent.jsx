'use client';

import React, { useState } from 'react';

const SimpleClientComponent = ({ content }) => {
  const [shown, setShown] = useState(true);

  return (
    <div>
      <button
        onClick={() => {
          setShown(!shown);
        }}
        type="button"
      >
        Toggle
      </button>
      {shown && <div>{content}</div>}
    </div>
  );
};

export default SimpleClientComponent;
