# frozen_string_literal: true

require "webmock"
require "httpx/adapters/webmock"
require "webmock/rspec"

# WebMock is now available for tests that need HTTP stubbing.
# Tests using WebMock should call WebMock.disable_net_connect! in their before block
# and WebMock.reset! in their after block if needed.
