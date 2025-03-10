import React from 'react';
import fetch from 'node-fetch';

const User = async ({ userId }) => {
  const user = await (await fetch(`http://localhost:3000/api/users/${userId}`)).json();

  return (
    <p>
      By <span style={{ fontWeight: 'bold' }}>{user.name}</span>
    </p>
  );
};

export default User;
