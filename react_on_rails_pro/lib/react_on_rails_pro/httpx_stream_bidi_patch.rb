# frozen_string_literal: true

require "httpx"

#
# Temporary patch for HTTPX stream_bidi plugin retry bug
#
# Issue: https://github.com/HoneyryderChuck/httpx/issues/124
#
# Problem: When a streaming request fails and is retried, the @headers_sent
# flag is not reset. This causes the :body callback to fire prematurely on
# retry, leading to re-entrant handle() calls that crash with:
#   HTTP2::Error::InternalError
#
# This patch resets @headers_sent when transitioning back to :idle state.
#
# Can be removed once fixed upstream in httpx gem.
#

HTTPX::Plugins.load_plugin(:stream_bidi)

if defined?(HTTPX::Plugins::StreamBidi)
  module HTTPX
    module Plugins
      module StreamBidi
        module RequestMethodsRetryFix
          def transition(nextstate)
            @headers_sent = false if nextstate == :idle

            super
          end
        end

        RequestMethods.prepend(RequestMethodsRetryFix)
      end
    end
  end
end
