# frozen_string_literal: true

require "httpx"

#
# Temporary patches for HTTPX stream_bidi plugin bugs
#
# These patches can be removed once fixed upstream in httpx gem.
#

HTTPX::Plugins.load_plugin(:stream_bidi)

if defined?(HTTPX::Plugins::StreamBidi)
  module HTTPX
    module Plugins
      module StreamBidi
        #
        # Patch 1: Fix missing `inflight?` method on Signal class
        #
        # Issue: When using HTTPX with both `persistent: true` and `.plugin(:stream_bidi)`,
        # calling `session.close` raises NoMethodError: undefined method `inflight?` for
        # an instance of HTTPX::Plugins::StreamBidi::Signal
        #
        # Root cause: The StreamBidi::Signal class is registered as a selectable in the
        # selector but doesn't implement the `inflight?` method required by Selector#terminate
        # (called during session close at lib/httpx/selector.rb:64)
        #
        # This patch adds the missing `inflight?` method to Signal. The method returns false
        # because Signal objects are just pipe-based notification mechanisms to wake up the
        # selector loop - they never have "inflight" HTTP requests or pending data buffers.
        #
        # The `unless method_defined?` guard ensures this patch won't override the method
        # when the official fix is released, making it safe to keep in the codebase.
        #
        # Affected versions: httpx 1.5.1 (and possibly earlier)
        #
        class Signal
          unless method_defined?(:inflight?)
            def inflight?
              false
            end
          end
        end

        #
        # Patch 2: Fix @headers_sent flag not reset on retry
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
