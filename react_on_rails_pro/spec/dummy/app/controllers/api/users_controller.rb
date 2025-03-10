# frozen_string_literal: true

module Api
  class UsersController < BaseController
    def index
      users = User.all
      render json: users
    end

    def show
      user = User.find(params[:id])
      render json: user
    end

    def create
      user = User.new(user_params)
      if user.save
        render json: user, status: :created
      else
        render_error(user.errors.full_messages)
      end
    end

    private

    def user_params
      params.require(:user).permit(:name, :email)
    end
  end
end
