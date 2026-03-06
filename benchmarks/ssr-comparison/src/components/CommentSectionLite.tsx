import React from 'react';
import CommentThreadLite from '../client/CommentThreadLite';
import type { Comment } from '../data';

function countComments(comments: Comment[]): number {
  return comments.reduce((sum, c) => sum + 1 + countComments(c.replies), 0);
}

export default function CommentSectionLite({ comments }: { comments: Comment[] }) {
  const total = countComments(comments);

  return (
    <section className="comment-section">
      <h2 className="section-title">Discussion</h2>
      <p className="comment-count">{total} comments</p>
      <div className="comment-list">
        {comments.map((comment) => (
          <CommentThreadLite key={comment.id} comment={comment} />
        ))}
      </div>
    </section>
  );
}
