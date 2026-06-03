# frozen_string_literal: true

require_relative "spec_helper"
require "tmpdir"
require_relative "../lib/benchmark_routes"

RSpec.describe "benchmark route discovery helpers" do
  describe "#benchmark_routes_from_rails_routes_output" do
    it "keeps benchmarkable GET routes and skips unsupported ones" do
      routes_output = <<~TEXT
        --[ Route 1 ]-------------------------------------------------------------------
        Prefix            | root
        Verb              | GET
        URI               | /
        Controller#Action | pages#index
        --[ Route 2 ]-------------------------------------------------------------------
        Prefix            | client_side_hello_world
        Verb              | GET
        URI               | /client_side_hello_world(.:format)
        Controller#Action | pages#client_side_hello_world
        --[ Route 3 ]-------------------------------------------------------------------
        Prefix            | redis_receiver_for_testing
        Verb              | GET
        URI               | /redis_receiver_for_testing(.:format)
        Controller#Action | pages#redis_receiver_for_testing
        --[ Route 4 ]-------------------------------------------------------------------
        Prefix            | rails_conductor_inbound_email
        Verb              | GET
        URI               | /rails/conductor/action_mailbox/inbound_emails/:id(.:format)
        Controller#Action | pages#show
        --[ Route 5 ]-------------------------------------------------------------------
        Prefix            | react_router
        Verb              | GET
        URI               | /react_router(/*all)(.:format)
        Controller#Action | react_router#index
        --[ Route 6 ]-------------------------------------------------------------------
        Prefix            | turbo_stream_send_hello_world
        Verb              | POST
        URI               | /turbo_stream_send_hello_world(.:format)
        Controller#Action | pages#turbo_stream_send_hello_world
      TEXT

      expect(benchmark_routes_from_rails_routes_output(routes_output)).to eq(
        ["/", "/client_side_hello_world", "/react_router"]
      )
    end

    it "skips intentional error/anti-pattern demo routes" do
      routes_output = <<~TEXT
        --[ Route 1 ]-------------------------------------------------------------------
        Prefix            | react_helmet_broken
        Verb              | GET
        URI               | /react_helmet_broken(.:format)
        Controller#Action | pages#react_helmet_broken
        --[ Route 2 ]-------------------------------------------------------------------
        Prefix            | context_function_return_jsx
        Verb              | GET
        URI               | /context_function_return_jsx(.:format)
        Controller#Action | pages#context_function_return_jsx
        --[ Route 3 ]-------------------------------------------------------------------
        Prefix            | pure_component_wrapped_in_function
        Verb              | GET
        URI               | /pure_component_wrapped_in_function(.:format)
        Controller#Action | pages#pure_component_wrapped_in_function
        --[ Route 4 ]-------------------------------------------------------------------
        Prefix            | server_side_hello_world
        Verb              | GET
        URI               | /server_side_hello_world(.:format)
        Controller#Action | pages#server_side_hello_world
      TEXT

      expect(benchmark_routes_from_rails_routes_output(routes_output)).to eq(["/server_side_hello_world"])
    end

    it "resets on the route separator so field-order changes don't misclassify routes" do
      # The parser must key off the `--[ Route N ]--` separator (the real block
      # delimiter), not assume Controller#Action is the last field of every block.
      # Here URI is emitted after Controller#Action; a Controller#Action-keyed flush
      # would read the URI before it's set and crash, whereas a separator-keyed
      # parser captures both routes correctly.
      routes_output = <<~TEXT
        --[ Route 1 ]-------------------------------------------------------------------
        Prefix            | client_side_hello_world
        Verb              | GET
        Controller#Action | pages#client_side_hello_world
        URI               | /client_side_hello_world(.:format)
        --[ Route 2 ]-------------------------------------------------------------------
        Prefix            | server_side_hello_world
        Verb              | GET
        Controller#Action | pages#server_side_hello_world
        URI               | /server_side_hello_world(.:format)
      TEXT

      expect(benchmark_routes_from_rails_routes_output(routes_output)).to eq(
        ["/client_side_hello_world", "/server_side_hello_world"]
      )
    end

    it "skips routes with a required glob segment" do
      routes_output = <<~TEXT
        --[ Route 1 ]-------------------------------------------------------------------
        Prefix            | legacy_catch_all
        Verb              | GET
        URI               | /legacy/*path(.:format)
        Controller#Action | pages#legacy
      TEXT

      expect(benchmark_routes_from_rails_routes_output(routes_output)).to eq([])
    end

    it "skips an incomplete block missing Controller#Action instead of crashing" do
      # A separator/end-of-block flush runs on every accumulated block, so a GET
      # block that never emitted a Controller#Action line (e.g. a future
      # `rails routes` format change) must be skipped rather than raise.
      routes_output = <<~TEXT
        --[ Route 1 ]-------------------------------------------------------------------
        Prefix            | mystery
        Verb              | GET
        URI               | /mystery(.:format)
      TEXT

      expect(benchmark_routes_from_rails_routes_output(routes_output)).to eq([])
    end

    it "skips an incomplete block missing URI instead of crashing" do
      routes_output = <<~TEXT
        --[ Route 1 ]-------------------------------------------------------------------
        Prefix            | mystery
        Verb              | GET
        Controller#Action | pages#mystery
      TEXT

      expect(benchmark_routes_from_rails_routes_output(routes_output)).to eq([])
    end
  end

  describe "#route_has_required_params?" do
    it "treats a dynamic segment as a required param" do
      expect(route_has_required_params?("/users/:id(.:format)")).to be(true)
    end

    it "ignores optional segments" do
      expect(route_has_required_params?("/users(/:id)(.:format)")).to be(false)
    end

    it "treats a required glob segment as a required param" do
      expect(route_has_required_params?("/legacy/*path")).to be(true)
    end

    it "ignores an optional glob segment" do
      expect(route_has_required_params?("/react_router(/*all)(.:format)")).to be(false)
    end

    it "detects a required glob even when an optional glob is also present" do
      # Optional parens are stripped before glob detection, so an optional glob
      # must not mask a sibling required one.
      expect(route_has_required_params?("/a(/*opt)/b/*req(.:format)")).to be(true)
    end
  end

  describe "#benchmark_routes_for_app" do
    it "runs rails routes in the app directory" do
      Dir.mktmpdir do |app_dir|
        routes_output = <<~TEXT
          --[ Route 1 ]-------------------------------------------------------------------
          Prefix            | client_side_hello_world
          Verb              | GET
          URI               | /client_side_hello_world(.:format)
          Controller#Action | pages#client_side_hello_world
        TEXT
        status = instance_double(Process::Status, success?: true)

        allow(Open3).to receive(:capture3).with(
          hash_including("RAILS_ENV" => "production"),
          "bundle",
          "exec",
          "rails",
          "routes",
          "--expanded",
          chdir: app_dir
        ).and_return([routes_output, "", status])

        expect(benchmark_routes_for_app(app_dir, nil)).to eq(["/client_side_hello_world"])
      end
    end

    it "honors explicitly requested routes even when they are on the skip-list" do
      # The NON_BENCHMARK_ROUTES filter applies to auto-discovery only; an explicit
      # ROUTES= request must still benchmark a skip-listed demo route on demand.
      expect(
        benchmark_routes_for_app("unused", "/react_helmet_broken,/context_function_return_jsx")
      ).to eq(["/react_helmet_broken", "/context_function_return_jsx"])
    end

    it "raises when rails routes fails" do
      Dir.mktmpdir do |app_dir|
        status = instance_double(Process::Status, success?: false)

        allow(Open3).to receive(:capture3).and_return(["", "boom", status])

        expect do
          benchmark_routes_for_app(app_dir, nil)
        end.to raise_error("Failed to get routes from #{app_dir}")
      end
    end
  end
end
