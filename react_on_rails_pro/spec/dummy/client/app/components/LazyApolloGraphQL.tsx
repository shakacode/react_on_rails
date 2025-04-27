import React, { useState, useRef } from 'react';
import { useSSRComputation } from '@shakacode/use-ssr-computation.macro';
import { setErrorHandler } from '@shakacode/use-ssr-computation.runtime';
import { useLazyMutation } from '../utils/useLazyMutation';

setErrorHandler((error) => {
  throw error;
});

const UserPanel = () => {
  const [userId, setUserId] = useState(1);
  const newNameInputRef = useRef<HTMLInputElement | null>(null);

  const data = useSSRComputation('../ssr-computations/userQuery.ssr-computation', [userId], {}) as
    | undefined
    | {
        user: { name: string; email: string };
      };
  const [updateUserMutation, { errors: updateError, loading: updating }] = useLazyMutation(() =>
    import('../utils/lazyApolloOperations').then(
      (lazyApolloOperations) => lazyApolloOperations.UPDATE_USER_MUTATION,
    ),
  );

  const renderUserInfo = () => {
    if (!data) {
      return <div>Loading...</div>;
    }
    const { name, email } = data.user;
    return (
      <p>
        <b>{name}: </b>
        {email}
      </p>
    );
  };

  const changeUser = () => {
    setUserId((prevState) => (prevState === 1 ? 2 : 1));
  };

  const updateUser = () => {
    const newName = newNameInputRef.current?.value;
    if (!newName) return;
    void updateUserMutation({ newName, userId });
  };

  const buttonStyle = {
    background: 'rgba(51, 51, 51, 0.05)',
    border: '1px solid rgba(51, 51, 51, 0.1)',
    borderRadius: '4px',
    padding: '4px 8px',
  };
  return (
    <div>
      {renderUserInfo()}
      <button style={buttonStyle} onClick={changeUser} type="button">
        Change User
      </button>
      <br />
      <br />
      <div>
        <b>Update User</b>
      </div>
      <label htmlFor="newName">
        New User Name:
        <input id="newName" type="text" ref={newNameInputRef} />
      </label>
      <br />
      <button
        style={buttonStyle}
        className="bg-blue-500 hover:bg-blue-700"
        onClick={updateUser}
        type="button"
      >
        Update User
      </button>

      {updating && <div>Updating...</div>}
      {updateError && <div style={{ color: 'red' }}>Error while updating User: {updateError.toString()}</div>}
    </div>
  );
};

const UserPanels = () => {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-evenly' }}>
      <UserPanel />
      <UserPanel />
    </div>
  );
};

export default UserPanels;
