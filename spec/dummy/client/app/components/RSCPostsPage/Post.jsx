import React, { Suspense } from 'react';
import moment from 'moment';
import Comments from './Comments';
import Spinner from '../Spinner';

const Post = ({ post, artificialDelay }) => {
  // render the post with its thumbnail
  return (
    <div style={{ border: '1px solid black', margin: '10px', padding: '10px' }}>
      <h1>{post.title}</h1>
      <p>{post.body}</p>
      <p>
        Created <span style={{ fontWeight: 'bold' }}>{moment(post.created_at).fromNow()}</span>
      </p>
      <img src="https://placehold.co/200" alt={post.title} />
      <Suspense fallback={<Spinner />}>
        <Comments postId={post.id} artificialDelay={artificialDelay} />
      </Suspense>
    </div>
  );
};

export default Post;
