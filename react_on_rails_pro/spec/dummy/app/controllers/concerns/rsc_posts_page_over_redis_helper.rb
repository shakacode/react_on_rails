# frozen_string_literal: true

module RscPostsPageOverRedisHelper
  extend ActiveSupport::Concern

  private

  def artificial_delay
    delay = params[:artificial_delay].to_i
    # Cap delay to prevent DoS attacks
    [delay, 10_000].min.clamp(0, 10_000)
  end

  def write_posts_and_comments_to_redis(redis)
    posts = fetch_posts
    add_posts_to_stream(redis, posts)
    write_comments_for_posts_to_redis(redis, posts)
    redis.xadd("stream:#{@request_id}", { "end" => "true" })
  end

  def add_posts_to_stream(redis, posts)
    Rails.logger.info "Adding posts to stream #{@request_id}"
    redis.xadd("stream:#{@request_id}", { ":posts" => posts.to_json })
  end

  def write_comments_for_posts_to_redis(redis, posts)
    posts.each do |post|
      post_comments = fetch_post_comments(post, [])
      redis.xadd("stream:#{@request_id}", { ":comments:#{post[:id]}" => post_comments.to_json })
      post_comments.each do |comment|
        user = fetch_comment_user(comment)
        redis.xadd("stream:#{@request_id}", { ":user:#{comment[:user_id]}" => user.to_json })
      end
    end
  end

  def fetch_posts
    posts = Post.with_delay(artificial_delay)
    posts.group_by { |post| post[:user_id] }.map { |_, user_posts| user_posts.first }
  end

  def fetch_post_comments(post, all_posts_comments)
    post_id = post["id"]
    post_comments = Comment.with_delay(artificial_delay).where(post_id: post_id)
    all_posts_comments.concat(post_comments)
    post_comments
  end

  def fetch_comment_user(comment)
    user_id = comment["user_id"]
    User.with_delay(artificial_delay).find(user_id)
  end
end
