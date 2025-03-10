import React from 'react';
import _ from 'lodash';
import ToggleContainer from './ToggleContainer';
import PreloadedComment from './PreloadedComment';

const PreloadedComments = ({ post }) => {
  const postComments = post.comments;

  const prepareComment = (comment) => {
    const safeComment = _.pick(comment, ['body', 'user_id', 'user']);
    const truncatedComment = _.truncate(safeComment.body, { length: 100 });
    return { ...safeComment, body: truncatedComment };
  };

  return (
    <ToggleContainer childrenTitle="Comments">
      <div>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>Comments</h2>
        {postComments.map((comment) => (
          <ToggleContainer key={comment.id} childrenTitle="Comment">
            <PreloadedComment comment={prepareComment(comment)} />
          </ToggleContainer>
        ))}
      </div>
    </ToggleContainer>
  );
};

export default PreloadedComments;
