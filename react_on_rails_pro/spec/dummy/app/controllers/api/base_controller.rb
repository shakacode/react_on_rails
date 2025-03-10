# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token

    private

    def render_error(message, status = :unprocessable_entity)
      render json: { error: message }, status: status
    end
  end
end
