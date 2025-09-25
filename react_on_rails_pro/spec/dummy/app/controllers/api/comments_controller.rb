# frozen_string_literal: true

module Api
  class CommentsController < BaseController
    before_action :set_post

    def index
      comments = @post.comments
      render json: comments
    end

    def create
      comment = @post.comments.build(comment_params)
      if comment.save
        render json: comment, status: :created
      else
        render_error(comment.errors.full_messages)
      end
    end

    private

    def set_post
      @post = Post.find(params[:post_id])
    end

    def comment_params
      params.require(:comment).permit(:body, :user_id)
    end
  end
end
