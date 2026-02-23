# frozen_string_literal: true

class HelloWorldController < ApplicationController
  layout "react_on_rails_default"

  def index
    @hello_world_props = { name: "Stranger" }
  end
end
