'use client';

import React, { useState } from 'react';
import type { Comment } from '../data';

export default function CommentThread({ comment }: { comment: Comment }) {
  const [collapsed, setCollapsed] = useState(false);
  const [showReply, setShowReply] = useState(false);

  return (
    <div className="comment-thread" data-comment-id={comment.id}>
      <div className="comment-header">
        <button className="collapse-toggle" onClick={() => setCollapsed(!collapsed)}>
          {collapsed ? '[+]' : '[-]'}
        </button>
        <span className="comment-author">{comment.author}</span>
        <span className="comment-date"> &middot; {comment.date}</span>
      </div>
      {!collapsed && (
        <>
          <div className="comment-body">
            <p>{comment.text}</p>
          </div>
          <div className="comment-actions">
            <button className="reply-toggle" onClick={() => setShowReply(!showReply)}>
              {showReply ? 'Cancel' : 'Reply'}
            </button>
          </div>
          {showReply && (
            <div className="reply-form">
              <textarea placeholder="Write a reply..." rows={3} />
              <button className="submit-reply">Submit</button>
            </div>
          )}
          {comment.replies.length > 0 && (
            <div className="comment-replies">
              {comment.replies.map((reply) => (
                <CommentThread key={reply.id} comment={reply} />
              ))}
            </div>
          )}
        </>
      )}
    </div>
  );
}
