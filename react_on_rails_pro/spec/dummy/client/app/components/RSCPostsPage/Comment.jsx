import React, { Suspense } from 'react';
import User from './User';

const Comment = ({ comment, fetchUser }) => {
  return (
    <div>
      <p>{comment.body}</p>
      <Suspense fallback={<div>Loading User...</div>}>
        <User userId={comment.user_id} fetchUser={fetchUser} />
      </Suspense>
    </div>
  );
};

export default Comment;
