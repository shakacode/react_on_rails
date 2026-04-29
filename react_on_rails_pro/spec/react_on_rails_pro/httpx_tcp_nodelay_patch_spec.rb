# frozen_string_literal: true

require_relative "spec_helper"

describe ReactOnRailsPro::HttpxTcpNodelayPatch do
  it "is prepended into HTTPX::TCP" do
    expect(HTTPX::TCP.ancestors).to include(described_class)
  end

  it "sets TCP_NODELAY=1 on every socket the wrapped build_socket returns" do
    fake_socket = instance_double(Socket)
    expect(fake_socket).to receive(:setsockopt).with(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

    base = Class.new do
      define_method(:build_socket) { fake_socket }
    end
    base.prepend(described_class)

    expect(base.new.build_socket).to be(fake_socket)
  end
end
