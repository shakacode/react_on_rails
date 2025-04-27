import React from 'react';
import fetch from 'node-fetch';
import _ from 'lodash';
import ToggleContainer from './ToggleContainer';
import Comment from './Comment';

const Comments = async ({ postId, artificialDelay }) => {
  const postComments = await (await fetch(`http://localhost:3000/api/posts/${postId}/comments`)).json();
  await new Promise((resolve) => {
    setTimeout(resolve, artificialDelay);
  });

  const prepareComment = (comment) => {
    const safeComment = _.pick(comment, ['body', 'user_id']);
    const truncatedComment = _.truncate(safeComment.body, { length: 100 });
    return { ...safeComment, body: truncatedComment };
  };

  return (
    <ToggleContainer childrenTitle="Comments">
      <div>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>Comments</h2>
        {postComments.map((comment) => (
          <ToggleContainer key={comment.id} childrenTitle="Comment">
            <Comment comment={prepareComment(comment)} />
          </ToggleContainer>
        ))}
      </div>
    </ToggleContainer>
  );
};

export default Comments;
