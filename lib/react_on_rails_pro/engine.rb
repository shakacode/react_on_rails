# frozen_string_literal: true

require "rails/railtie"

module ReactOnRailsPro
  class Engine < Rails::Engine
    initializer "react_on_rails_pro.routes" do
      ActionDispatch::Routing::Mapper.include ReactOnRailsPro::Routes
    end
  end
end
