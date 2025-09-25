# frozen_string_literal: true

module Api
  class PostsController < BaseController
    def index
      posts = Post.all
      render json: posts
    end

    def show
      post = Post.includes(:user, :comments).find(params[:id])
      render json: post, include: %i[user comments]
    end

    def create
      post = Post.new(post_params)
      if post.save
        render json: post, status: :created
      else
        render_error(post.errors.full_messages)
      end
    end

    def update
      post = Post.find(params[:id])
      if post.update(post_params)
        render json: post
      else
        render_error(post.errors.full_messages)
      end
    end

    def destroy
      post = Post.find(params[:id])
      post.destroy
      head :no_content
    end

    private

    def post_params
      params.require(:post).permit(:title, :body, :user_id)
    end
  end
end
