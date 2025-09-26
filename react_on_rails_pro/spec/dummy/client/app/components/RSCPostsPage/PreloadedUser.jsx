import React from 'react';

const PreloadedUser = ({ user }) => {
  return (
    <p>
      By <span style={{ fontWeight: 'bold' }}>{user.name}</span>
    </p>
  );
};

export default PreloadedUser;
