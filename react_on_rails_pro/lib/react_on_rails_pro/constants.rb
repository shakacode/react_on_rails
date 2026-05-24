# frozen_string_literal: true

module ReactOnRailsPro
  # Status code 400 indicates the renderer rejected the request payload or encountered an unhandled render error.
  STATUS_BAD_REQUEST = 400
  # Status code 410 means to resend the request with the updated bundle.
  STATUS_SEND_BUNDLE = 410
  # Status code 412 means protocol versions are incompatible between the server and the renderer.
  STATUS_INCOMPATIBLE = 412

  # Env var used by the renderer load harness (and future async-http branch)
  # to record which transport is active. No behavior switching here.
  RENDERER_TRANSPORT_ENV = "REACT_ON_RAILS_RENDERER_TRANSPORT"
  DEFAULT_RENDERER_TRANSPORT = "httpx"
end
