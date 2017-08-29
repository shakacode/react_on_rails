# frozen_string_literal: true

if File.basename(ENV["BUNDLE_GEMFILE"] || "") == "Gemfile.rails32"
  Dummy::Application.config.secret_token = "52c8a2ded80d8414f65356e7e0e51917217"\
                                           "6d9e8e15ffa7f7cebee01e6f429867cde8a6409974b5"\
                                           "f060b9183694132a745b6bcedc5f05bf2ae94bfa07af9d2d9"

  Dummy::Application.config.session_store :cookie_store, key: "_hello_session"
  ActiveSupport.on_load(:action_controller) do
    wrap_parameters format: [:json]
  end
  ActiveSupport.on_load(:active_record) do
    self.include_root_in_json = false
  end
else
  Rails.application.config.assets.version = "1.0"
  Rails.application.config.assets.paths << Rails.root.join("app", "assets", "webpack")
  Rails.application.config.assets.precompile << "server-bundle.js"
  type = ENV["REACT_ON_RAILS_ENV"] == "HOT" ? "non_webpack" : "static"
  Rails.application.config.assets.precompile +=
    [
      "application_#{type}.js",
      "application_#{type}.css"
    ]

  Rails.application.config.action_dispatch.cookies_serializer = :json
  Rails.application.config.filter_parameters += [:password]
  Rails.application.config.session_store :cookie_store, key: "_dummy_session"
  ActiveSupport.on_load(:action_controller) do
    wrap_parameters format: [:json] if respond_to?(:wrap_parameters)
  end
end
