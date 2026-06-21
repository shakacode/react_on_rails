# frozen_string_literal: true

require_relative "../spec_helper"

# rubocop:disable Metrics/ModuleLength
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
        rescue StandardError => e
          # Rescue StandardError (not just ReactOnRails::Error) so an unexpected error type
          # surfaces as a clean `be_a(ReactOnRails::Error)` expectation failure rather than a
          # confusing raw exception out of the helper.
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
          original_legacy = ENV.fetch("RENDERER_URL", nil)
          ENV.delete("REACT_RENDERER_URL")
          ENV.delete("RENDERER_URL")
          example.run
        ensure
          if original.nil?
            ENV.delete("REACT_RENDERER_URL")
          else
            ENV["REACT_RENDERER_URL"] = original
          end
          if original_legacy.nil?
            ENV.delete("RENDERER_URL")
          else
            ENV["RENDERER_URL"] = original_legacy
          end
        end

        context "when the renderer connection is blocked (Errno::EPERM, the issue #3604 case)" do
          let(:error) { Errno::EPERM.new("connect(2) for 127.0.0.1:3800") }

          it "raises a ReactOnRails::Error" do
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

          it "names the host and port extracted from the wrapped cause" do
            message = render_error_for(error).message
            expect(message).to include("at 127.0.0.1:3800")
          end
        end

        context "when an EPERM connect signature survives only as the error's #cause" do
          let(:error) { wrapped_error(Errno::EPERM, "connect(2) for 127.0.0.1:3800", "renderer request failed") }

          it "is classified as a connection failure via the cause message" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer at 127.0.0.1:3800")
            expect(message).not_to include("Check your webpack configuration")
          end
        end

        context "when an HTTP-served server bundle cannot be loaded" do
          let(:error) do
            ReactOnRails::ServerBundleLoadError.new(
              "You specified server rendering JS file: http://localhost:3035/server-bundle.js, " \
              "but it cannot be read.\nError is: Failed to open TCP connection to localhost:3035"
            )
          end

          it "preserves the bundle-load failure instead of reporting a renderer connection failure" do
            raised_error = render_error_for(error)
            expect(raised_error).to be_a(ReactOnRails::ServerBundleLoadError)
            expect(raised_error.message).to include("server-bundle.js")
            expect(raised_error.message).to include("cannot be read")
            expect(raised_error.message).not_to include("could not connect to the Node renderer")
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

        context "when the error uses the Net::HTTP 'Failed to open TCP connection' format" do
          let(:error) do
            StandardError.new("Failed to open TCP connection to 127.0.0.1:3800 (Connection refused)")
          end

          it "is classified as a connection failure and names the host/port" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer at 127.0.0.1:3800")
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

        context "when REACT_RENDERER_URL embeds credentials" do
          let(:error) { Errno::ECONNREFUSED.new }

          before { ENV["REACT_RENDERER_URL"] = "https://:s3cr3t@renderer.example.com:3800" }

          it "redacts the password from the connection error message" do
            message = render_error_for(error).message
            expect(message).to include("renderer.example.com:3800")
            expect(message).not_to include("s3cr3t")
          end
        end

        context "when the error message itself names a renderer URL with embedded credentials" do
          let(:error) do
            StandardError.new(
              "Connection error on renderer request: failed to open TCP connection to " \
              "https://user:sekret@renderer.example.com:3800"
            )
          end

          it "redacts credentials from the target named in the headline" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer at https://renderer.example.com:3800")
            # The credentialed form must not appear in the target position. (The raw exception
            # text is still echoed verbatim under "Caught error:" — pre-existing behavior for
            # every error type in this file — so the password can survive there.)
            expect(message).not_to include("at https://user:sekret@")
          end
        end

        context "when only the legacy RENDERER_URL is set and the error carries no host/port" do
          let(:error) { Errno::ECONNREFUSED.new }

          before { ENV["RENDERER_URL"] = "http://legacy-host:3800" }

          it "falls back to the legacy RENDERER_URL for the target" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer at http://legacy-host:3800")
          end

          it "keeps the checklist consistent by naming RENDERER_URL rather than calling it unset" do
            message = render_error_for(error).message
            expect(message).to include('RENDERER_URL is currently "http://legacy-host:3800"')
            expect(message).not_to include("REACT_RENDERER_URL is not set")
          end
        end

        context "when REACT_RENDERER_URL is present but blank and the legacy RENDERER_URL is set" do
          let(:error) { Errno::ECONNREFUSED.new }

          before do
            ENV["REACT_RENDERER_URL"] = ""
            ENV["RENDERER_URL"] = "http://legacy-host:3800"
          end

          it "treats the blank value as unset and uses the legacy RENDERER_URL" do
            message = render_error_for(error).message
            expect(message).to include("could not connect to the Node renderer at http://legacy-host:3800")
            expect(message).not_to include('is currently ""')
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

      describe ".read_bundle_js_code" do
        it "raises a bundle-load error when an HTTP server bundle cannot be read" do
          server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

          allow(ReactOnRails::Utils).to receive_messages(
            server_bundle_js_file_path: server_bundle_url,
            server_bundle_path_is_http?: true
          )
          allow(Net::HTTP).to receive(:get_response).and_raise(
            Errno::ECONNREFUSED.new("connect(2) for localhost:3035")
          )

          expect do
            described_class.read_bundle_js_code
          end.to raise_error(ReactOnRails::ServerBundleLoadError) { |error|
            expect(error.message).to include(server_bundle_url)
            expect(error.message).to include("cannot be read")
            expect(error.message).to include("connect(2) for localhost:3035")
          }
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
