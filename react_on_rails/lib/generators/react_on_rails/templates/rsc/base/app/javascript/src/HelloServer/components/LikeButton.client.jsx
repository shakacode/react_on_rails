'use client';

import React, { useState } from 'react';

const LikeButton = ({ initialCount = 0 }) => {
  const [count, setCount] = useState(initialCount);

  return (
    <button type="button" onClick={() => setCount((value) => value + 1)}>
      Celebrate streaming RSC ({count})
    </button>
  );
};

export default LikeButton;
