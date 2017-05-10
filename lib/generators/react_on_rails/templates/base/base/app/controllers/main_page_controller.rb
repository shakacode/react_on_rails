class MainPageController < ApplicationController
  layout "main_page"

  def index
    @main_page_props = { name: "Stranger" }
  end
end
