import React from 'react';
import PreloadedUser from './PreloadedUser';

const PreloadedComment = ({ comment }) => {
  return (
    <div>
      <p>{comment.body}</p>
      <PreloadedUser user={comment.user} />
    </div>
  );
};

export default PreloadedComment;
