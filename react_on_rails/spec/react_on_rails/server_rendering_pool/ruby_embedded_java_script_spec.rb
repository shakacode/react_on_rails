# frozen_string_literal: true

require_relative "../spec_helper"

module ReactOnRails
  module ServerRenderingPool
    describe RubyEmbeddedJavaScript do
      # See issue #3604: renderer connection failures were reported with the misleading
      # "Error evaluating server bundle. Check your webpack configuration." message even
      # though the bundle was never evaluated because the renderer could not be reached.
      describe ".exec_server_render_js error classification" do
        let(:render_options) do
          instance_double(
            ReactOnRails::ReactComponent::RenderOptions,
            trace: false,
            streaming?: false
          )
        end

        def evaluator_raising(error)
          js_evaluator = class_double(described_class)
          allow(js_evaluator).to receive(:eval_js).and_raise(error)
          js_evaluator
        end

        def render_error_for(error)
          described_class.exec_server_render_js("someComponentJS()", render_options, evaluator_raising(error))
          raise "expected exec_server_render_js to raise"
        rescue ReactOnRails::Error => e
          e
        end

        # Builds an error whose #cause is an instance of cause_class, mimicking how the Pro
        # renderer client re-wraps the original Errno inside its own error.
        def wrapped_error(cause_class, cause_message, wrapper_message)
          begin
            raise cause_class, cause_message
          rescue cause_class
            raise StandardError, wrapper_message
          end
        rescue StandardError => e
          e
        end

        around do |example|
          original = ENV.fetch("REACT_RENDERER_URL", nil)
          ENV.delete("REACT_RENDERER_URL")
          example.run
        ensure
          if original.nil?
            ENV.delete("REACT_RENDERER_URL")
          else
            ENV["REACT_RENDERER_URL"] = original
          end
        end

        context "when the renderer connection is blocked (Errno::EPERM, the issue #3604 case)" do
          let(:error) { Errno::EPERM.new("connect(2) for 127.0.0.1:3800") }

          it "raises a ReactOnRails::Error" do
            expect { render_error_for(error) }.not_to raise_error
            expect(render_error_for(error)).to be_a(ReactOnRails::Error)
          end

          it "reports a renderer connection failure rather than a webpack/bundle error" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer")
            expect(message).not_to include("Error evaluating server bundle. Check your webpack configuration.")
          end

          it "names the host and port that could not be reached" do
            message = render_error_for(error).message
            expect(message).to include("at 127.0.0.1:3800")
          end

          it "points the user at REACT_RENDERER_URL and renderer liveness" do
            message = render_error_for(error).message
            expect(message).to include("REACT_RENDERER_URL")
            expect(message).to include("renderer process is running")
          end

          it "still includes the original caught error and support section" do
            message = render_error_for(error).message
            expect(message).to include("connect(2) for 127.0.0.1:3800")
            expect(message).to include("react_on_rails@shakacode.com")
          end
        end

        context "when the renderer refuses the connection (Errno::ECONNREFUSED)" do
          let(:error) { Errno::ECONNREFUSED.new("connect(2) for 127.0.0.1:3800") }

          it "is classified as a connection failure" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer at 127.0.0.1:3800")
            expect(message).not_to include("Check your webpack configuration")
          end
        end

        context "when the error is the Pro renderer client's wrapped connection error" do
          let(:error) do
            StandardError.new(
              "Connection error on renderer request: /bundles/abc123/render.\n" \
              "Original error:\nConnection refused - connect(2) for 127.0.0.1:3800\n"
            )
          end

          it "is classified as a connection failure via the message even though the class is generic" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer at 127.0.0.1:3800")
            expect(message).not_to include("Check your webpack configuration")
          end
        end

        context "when the connection Errno survives only as the error's #cause" do
          # The Pro renderer client wraps the original Errno (ReactOnRailsPro::Error ->
          # ConnectionError -> Errno::ECONNREFUSED). The wrapper message here carries no
          # connection signature, so classification must come from walking the cause chain.
          let(:error) { wrapped_error(Errno::ECONNREFUSED, "connect(2) for 127.0.0.1:3800", "renderer request failed") }

          it "is classified as a connection failure via the cause chain" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer")
            expect(message).not_to include("Check your webpack configuration")
          end
        end

        context "when the renderer request times out (Pro 'Time out error on renderer request')" do
          let(:error) do
            StandardError.new(
              "Time out error on renderer request: /bundles/abc123/render.\nOriginal error:\nTimed out!\n"
            )
          end

          it "is classified as a connection failure rather than a bundle error" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer")
            expect(message).not_to include("Check your webpack configuration")
          end
        end

        context "when REACT_RENDERER_URL is set but the error carries no host/port" do
          let(:error) { Errno::ECONNREFUSED.new }

          before { ENV["REACT_RENDERER_URL"] = "http://localhost:3800" }

          it "falls back to the configured REACT_RENDERER_URL for the target" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer at http://localhost:3800")
            expect(message).to include('REACT_RENDERER_URL is currently "http://localhost:3800"')
          end
        end

        context "when the bundle actually fails to evaluate" do
          let(:error) { RuntimeError.new("ReferenceError: SomeComponent is not defined") }

          it "keeps the existing webpack/server-bundle troubleshooting message" do
            message = render_error_for(error).message
            expect(message).to include("Error evaluating server bundle. Check your webpack configuration.")
            expect(message).not_to include("could not connect to the Node renderer")
          end
        end

        context "when an in-process bundle error merely mentions a connection (e.g. a component's own fetch)" do
          # A component fetching during SSR can fail with a JS-level "ECONNREFUSED" string,
          # but the renderer itself was reached. This must NOT be reclassified as a renderer
          # connectivity failure (the inverse of the issue #3604 bug); there is no Errno in
          # the chain and the message has no renderer/socket anchor.
          let(:error) { RuntimeError.new("Error: connect ECONNREFUSED 127.0.0.1:5432 (database)") }

          it "keeps the webpack/server-bundle message instead of blaming the renderer" do
            message = render_error_for(error).message
            expect(message).to include("Error evaluating server bundle. Check your webpack configuration.")
            expect(message).not_to include("could not connect to the Node renderer")
          end
        end

        context "when the bundle fails with the code-splitting 'self is not defined' error" do
          let(:error) { RuntimeError.new("ReferenceError: self is not defined") }

          it "retains the code-splitting hint" do
            message = render_error_for(error).message
            expect(message).to include("Error evaluating server bundle. Check your webpack configuration.")
            expect(message).to include("code-splitting incorrectly enabled")
          end
        end
      end
    end
  end
end
