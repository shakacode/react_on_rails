import React from 'react';
import _ from 'lodash';
import PreloadedPost from './PreloadedPost';

const PreloadedPosts = ({ posts, postsCount }) => {
  if (!posts || !Array.isArray(posts) || posts.length === 0) {
    return <div>No posts found</div>;
  }

  const postsByUser = _.groupBy(posts, 'user_id');
  const onePostPerUser = _.map(postsByUser, (group) => group[0]);
  const postsToShow = onePostPerUser.slice(0, postsCount);

  return (
    <div>
      {postsToShow.map((post) => (
        <PreloadedPost key={post.id} post={post} />
      ))}
    </div>
  );
};

export default PreloadedPosts;
