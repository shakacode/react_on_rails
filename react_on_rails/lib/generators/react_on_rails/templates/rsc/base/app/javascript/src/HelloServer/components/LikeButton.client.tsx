'use client';

import React, { useState } from 'react';

interface LikeButtonProps {
  initialCount?: number;
}

const LikeButton = ({ initialCount = 0 }: LikeButtonProps): React.JSX.Element => {
  const [count, setCount] = useState(initialCount);

  return (
    <button type="button" onClick={() => setCount((value) => value + 1)}>
      Celebrate streaming RSC ({count})
    </button>
  );
};

export default LikeButton;
