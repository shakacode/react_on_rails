# frozen_string_literal: true

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
  get "server_side_hello_world_hooks" => "pages#server_side_hello_world_hooks"
  get "client_side_log_throw" => "pages#client_side_log_throw"
  get "server_side_log_throw" => "pages#server_side_log_throw"
  get "server_side_log_throw_plain_js" => "pages#server_side_log_throw_plain_js"
  get "server_side_log_throw_raise" => "pages#server_side_log_throw_raise"
  get "server_side_log_throw_raise_invoker" => "pages#server_side_log_throw_raise_invoker"
  get "server_side_hello_world_es5" => "pages#server_side_hello_world_es5"
  get "server_side_redux_app" => "pages#server_side_redux_app"
  get "server_side_hello_world_with_options" => "pages#server_side_hello_world_with_options"
  get "server_side_redux_app_cached" => "pages#server_side_redux_app_cached"
  get "client_side_manual_render" => "pages#client_side_manual_render"
  get "deferred_render_with_server_rendering(/*all)" =>
    "pages#deferred_render_with_server_rendering", as: :deferred_render
  get "render_js" => "pages#render_js"
  get "react_router(/*all)" => "react_router#index", as: :react_router
  get "pure_component" => "pages#pure_component"
  get "css_modules_images_fonts_example" => "pages#css_modules_images_fonts_example"
  get "turbolinks_cache_disabled" => "pages#turbolinks_cache_disabled"
  get "rendered_html" => "pages#rendered_html"
  get "xhr_refresh" => "pages#xhr_refresh"
  get "react_helmet" => "pages#react_helmet"
  get "react_helmet_broken" => "pages#react_helmet_broken"
  get "broken_app" => "pages#broken_app"
  get "image_example" => "pages#image_example"
  get "server_render_with_timeout" => "pages#server_render_with_timeout"
  get "context_function_return_jsx" => "pages#context_function_return_jsx"
  get "pure_component_wrapped_in_function" => "pages#pure_component_wrapped_in_function"
end
