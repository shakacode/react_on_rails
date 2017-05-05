class HelloWorldController < ApplicationController
  layout "hello_world"

  def index
    @hello_world_props = { name: "Stranger" }
  end
end
