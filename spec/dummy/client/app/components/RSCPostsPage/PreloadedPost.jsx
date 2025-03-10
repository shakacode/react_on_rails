import React, { Suspense } from 'react';
import moment from 'moment';
import PreloadedComments from './PreloadedComments';

const PreloadedPost = ({ post }) => {
  // render the post with its thumbnail
  return (
    <div style={{ border: '1px solid black', margin: '10px', padding: '10px' }}>
      <h1>{post.title}</h1>
      <p>{post.body}</p>
      <p>
        Created <span style={{ fontWeight: 'bold' }}>{moment(post.created_at).fromNow()}</span>
      </p>
      <img src="https://placehold.co/200" alt={post.title} />
      <PreloadedComments post={post} />
    </div>
  );
};

export default PreloadedPost;
