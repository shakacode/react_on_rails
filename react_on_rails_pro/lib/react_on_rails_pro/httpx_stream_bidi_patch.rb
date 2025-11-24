# frozen_string_literal: true

# Temporary monkey-patch for HTTPX bug with stream_bidi plugin + persistent connections
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
# Can be removed once httpx releases an official fix.
# Affected versions: httpx 1.5.1 (and possibly earlier)
# See: https://github.com/HoneyryderChuck/httpx/issues/XXX

module HTTPX
  module Plugins
    module StreamBidi
      class Signal
        unless method_defined?(:inflight?)
          def inflight?
            false
          end
        end
      end
    end
  end
end
