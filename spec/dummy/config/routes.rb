Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root 'pages#index'

  get "client_side_hello_world" => "pages#client_side_hello_world"
  get "server_side_hello_world" => "pages#server_side_hello_world"
  get "server_side_log_throw" => "pages#server_side_log_throw"
  get "server_side_hello_world_es5" => "pages#server_side_hello_world_es5"
  get "server_side_redux_app" => "pages#server_side_redux_app"
  get "server_side_hello_world_with_options" => "pages#server_side_hello_world_with_options"
  get "server_side_redux_app_cached" => "pages#server_side_redux_app_cached"
  get "render_js" => "pages#render_js"
end
