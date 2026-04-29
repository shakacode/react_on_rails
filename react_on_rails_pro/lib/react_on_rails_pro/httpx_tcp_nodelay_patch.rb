# frozen_string_literal: true

require "httpx"
require "socket"

# httpx (as of 1.7.x) does not call setsockopt(TCP_NODELAY, 1) on its sockets,
# while net-http and async-http both do. With Nagle on, small HTTP/2 frame
# writes interact with Linux's delayed-ACK timer (tcp_delack_min = 40ms),
# producing a bimodal latency distribution with a second mode at ~40ms.
#
# Enabling TCP_NODELAY removes the 40ms tail and brings httpx h2 latency in
# line with net-http and async-http. In the Rails -> node-renderer transport
# (HTTP/2, persistent), this reclaims ~30-40% throughput and cuts p99 latency
# from ~45ms to ~12-21ms under load.
#
# Remove this patch once upstream httpx ships TCP_NODELAY by default
# (see https://github.com/HoneyryderChuck/httpx).
module ReactOnRailsPro
  module HttpxTcpNodelayPatch
    def build_socket
      sock = super
      sock.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      sock
    end
  end
end

HTTPX::TCP.prepend(ReactOnRailsPro::HttpxTcpNodelayPatch)
