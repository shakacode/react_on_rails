Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  root "pages#index"

  get "client_side_hello_world" => "pages#client_side_hello_world"
  get "client_side_hello_world_shared_store" => "pages#client_side_hello_world_shared_store"
  get "client_side_hello_world_shared_store_controller" => "pages#client_side_hello_world_shared_store_controller"
  get "client_side_hello_world_shared_store_defer" => "pages#client_side_hello_world_shared_store_defer"
  get "server_side_hello_world_shared_store" => "pages#server_side_hello_world_shared_store"
  get "server_side_hello_world_shared_store_controller" => "pages#server_side_hello_world_shared_store_controller"
  get "server_side_hello_world_shared_store_defer" => "pages#server_side_hello_world_shared_store_defer"
  get "server_side_hello_world" => "pages#server_side_hello_world"
  get "client_side_log_throw" => "pages#client_side_log_throw"
  get "server_side_log_throw" => "pages#server_side_log_throw"
  get "server_side_log_throw_raise" => "pages#server_side_log_throw_raise"
  get "server_side_hello_world_es5" => "pages#server_side_hello_world_es5"
  get "server_side_redux_app" => "pages#server_side_redux_app"
  get "server_side_hello_world_with_options" => "pages#server_side_hello_world_with_options"
  get "server_side_redux_app_cached" => "pages#server_side_redux_app_cached"
  get "render_js" => "pages#render_js"
  get "react_router(/*all)" => "react_router#index", as: :react_router
  get "pure_component" => "pages#pure_component"
  get "css_modules_images_fonts_example" => "pages#css_modules_images_fonts_example"
end
