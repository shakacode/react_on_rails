# frozen_string_literal: true

class PagesController < ApplicationController
  def index
    @props = {
      path: request.original_fullpath || "/"
    }
  end
end
