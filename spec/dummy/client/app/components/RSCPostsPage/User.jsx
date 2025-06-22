import React from 'react';

const User = async ({ userId, fetchUser }) => {
  const user = await fetchUser(userId);

  return (
    <p>
      By <span style={{ fontWeight: 'bold' }}>{user.name}</span>
    </p>
  );
};

export default User;
