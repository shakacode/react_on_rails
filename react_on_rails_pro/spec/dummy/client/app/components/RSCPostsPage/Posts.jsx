import React from 'react';
import _ from 'lodash';
import Post from './Post';

const Posts = async ({ artificialDelay, postsCount = 2, fetchPosts, fetchComments, fetchUser }) => {
  await new Promise((resolve) => {
    setTimeout(resolve, artificialDelay);
  });
  const posts = await fetchPosts();
  const postsByUser = _.groupBy(posts, 'user_id');
  const onePostPerUser = _.map(postsByUser, (group) => group[0]);
  const postsToShow = onePostPerUser.slice(0, postsCount);

  return (
    <div>
      {postsToShow.map((post) => (
        <Post
          key={post.id}
          post={post}
          artificialDelay={artificialDelay}
          fetchComments={fetchComments}
          fetchUser={fetchUser}
        />
      ))}
    </div>
  );
};

export default Posts;
