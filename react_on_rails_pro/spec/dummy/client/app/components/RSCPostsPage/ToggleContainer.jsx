import React, { useState } from 'react';

const ToggleContainer = ({ children, childrenTitle }) => {
  const [isVisible, setIsVisible] = useState(true);
  const showOrHideText = isVisible ? `Hide ${childrenTitle}` : `Show ${childrenTitle}`;

  React.useEffect(() => {
    console.log('ToggleContainer with title', childrenTitle);
  }, [childrenTitle]);

  return (
    <div style={{ border: '1px solid black', margin: '10px', padding: '10px' }}>
      <button
        className="toggle-button"
        onClick={() => setIsVisible(!isVisible)}
        style={{ border: '1px solid black' }}
        type="button"
      >
        {showOrHideText}
      </button>
      {isVisible && children}
    </div>
  );
};

export default ToggleContainer;
