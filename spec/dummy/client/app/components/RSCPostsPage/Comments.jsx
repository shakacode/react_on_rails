import React from 'react';
import _ from 'lodash';
import ToggleContainer from './ToggleContainerForServerComponents';
import Comment from './Comment';

const Comments = async ({ postId, artificialDelay, fetchComments, fetchUser }) => {
  const postComments = await fetchComments(postId);
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
            <Comment comment={prepareComment(comment)} fetchUser={fetchUser} />
          </ToggleContainer>
        ))}
      </div>
    </ToggleContainer>
  );
};

export default Comments;
