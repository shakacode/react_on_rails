# frozen_string_literal: true

class HomeController < ApplicationController
  protect_from_forgery with: :exception

  def index; end
end
