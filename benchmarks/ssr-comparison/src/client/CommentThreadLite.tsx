'use client';

import React, { useState } from 'react';
import type { Comment } from '../data';

/**
 * Simplified CommentThread: ~4 elements instead of ~8 per comment.
 * - Flattened header (single span instead of div > button + span + span)
 * - No collapse/reply UI (not relevant for SSR benchmark)
 */
export default function CommentThreadLite({ comment }: { comment: Comment }) {
  const [collapsed] = useState(false);

  return (
    <div className="comment-thread" data-comment-id={comment.id}>
      <span className="comment-header">{comment.author} &middot; {comment.date}</span>
      <p className="comment-body">{comment.text}</p>
      {!collapsed && comment.replies.length > 0 && (
        <div className="comment-replies">
          {comment.replies.map((reply) => (
            <CommentThreadLite key={reply.id} comment={reply} />
          ))}
        </div>
      )}
    </div>
  );
}
