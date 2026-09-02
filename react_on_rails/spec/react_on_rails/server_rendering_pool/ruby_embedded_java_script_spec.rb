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
        def stub_http_bundle_failure(error, bundle_url: "http://localhost:3035/webpack/development/server-bundle.js")
          allow(ReactOnRails::Utils).to receive_messages(
            server_bundle_js_file_path: bundle_url,
            server_bundle_path_is_http?: true
          )
          allow(Net::HTTP).to receive(:get_response).and_raise(error)
        end

        def stub_local_bundle_failure(error, bundle_path: "/tmp/server-bundle.js")
          allow(ReactOnRails::Utils).to receive_messages(
            server_bundle_js_file_path: bundle_path,
            server_bundle_path_is_http?: false
          )
          allow(File).to receive(:read).with(bundle_path).and_raise(error)
        end

        def bundle_load_error_message
          described_class.read_bundle_js_code
          raise "expected read_bundle_js_code to raise"
        rescue ReactOnRails::ServerBundleLoadError => e
          e.message
        end

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

        # See issue #4584: a non-2xx HTTP response (e.g. a 404 page from a proxy) was
        # returned as if it were bundle source, silently, instead of raising.
        context "when the HTTP-served bundle responds with a non-2xx status" do
          it "raises a bundle-load error naming the status and URL instead of returning the error body as source" do
            server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            not_found_response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
            not_found_response["content-type"] = "text/html; charset=utf-8"
            not_found_response.instance_variable_set(:@read, true)
            not_found_response.instance_variable_set(:@body, "<html><body>Not Found</body></html>")

            allow(Net::HTTP).to receive(:get_response).and_return(not_found_response)

            expect do
              described_class.read_bundle_js_code
            end.to raise_error(ReactOnRails::ServerBundleLoadError) { |error|
              expect(error.message).to include(server_bundle_url)
              expect(error.message).to include("404")
              expect(error.message).not_to include("<html>")
            }
          end
        end

        # No error message in this file's HTTP-bundle-loading path may leak a URL's embedded
        # basic-auth credentials. A non-2xx response is exactly the failure mode a bad-credentials
        # config produces (401/403), so the status-check path must not put the username or
        # password in the raised message. These specs call the public `read_bundle_js_code` entry
        # point (not the private `file_url_to_string`) because that is the real path every caller
        # goes through — `read_bundle_js_code`'s own rescue re-interpolates the raw URL
        # independently of whatever `file_url_to_string` does internally, so sanitizing only the
        # inner method would leave the credential leaking right back out through here.
        context "when the HTTP-served bundle URL embeds credentials and the response is non-2xx" do
          it "does not leak the credential into the raised error message" do
            server_bundle_url = "http://bundle-user:s3cr3t@localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            not_found_response = Net::HTTPNotFound.new("1.1", "404", "Not Found")
            not_found_response["content-type"] = "text/html; charset=utf-8"
            not_found_response.instance_variable_set(:@read, true)
            not_found_response.instance_variable_set(:@body, "<html><body>Not Found</body></html>")

            allow(Net::HTTP).to receive(:get_response).and_return(not_found_response)

            expect do
              described_class.read_bundle_js_code
            end.to raise_error(ReactOnRails::ServerBundleLoadError) { |error|
              expect(error.message).not_to include("s3cr3t")
              expect(error.message).not_to include("bundle-user")
              # The status and a usable (sanitized) URL must still be present for diagnosis.
              expect(error.message).to include("404")
              expect(error.message).to include("localhost:3035")
            }
          end
        end

        # read_bundle_js_code's own rescue (the outer wrapper around file_url_to_string) has the
        # identical interpolation gap on any other failure of Net::HTTP.get_response (e.g. a
        # connection error), so it must be sanitized too — this is the path a credentialed URL
        # actually takes when the connection itself fails.
        context "when the HTTP-served bundle URL embeds credentials and the connection fails" do
          it "does not leak the credential into the raised error message" do
            server_bundle_url = "http://bundle-user:s3cr3t@localhost:3035/webpack/development/server-bundle.js"
            stub_http_bundle_failure(
              Errno::ECONNREFUSED.new("connect(2) for localhost:3035"),
              bundle_url: server_bundle_url
            )

            message = bundle_load_error_message
            expect(message).not_to include("s3cr3t")
            expect(message).not_to include("bundle-user")
            expect(message).to include("localhost:3035")
            expect(message).to include("cannot be read")
          end
        end

        # A URL malformed enough that URI.parse itself raises (e.g. a space in the host) fails
        # before sanitized_renderer_url is ever applied to the `url` variable at the raise site —
        # URI::InvalidURIError's own message embeds the original credential-bearing string
        # verbatim, so that message must be scrubbed independently of the url variable.
        context "when the HTTP-served bundle URL embeds credentials and is malformed enough to fail URI parsing" do
          it "does not leak the credential into the raised error message" do
            server_bundle_url = "http://bundle-user:s3cr3t@bad host/webpack/development/server-bundle.js"
            stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

            message = bundle_load_error_message
            expect(message).not_to include("s3cr3t")
            expect(message).not_to include("bundle-user")
            # The error must still say the URL was malformed and show enough of it (host/path
            # minus credentials) for an operator to identify which configured URL failed.
            expect(message).to include("bad URI")
            expect(message).to include("bad host")
          end
        end

        context "when a credential URL has whitespace in its HTTP scheme delimiter" do
          it "redacts credentials even when the path is classified as a local bundle" do
            server_bundle_path = "http ://bundle-user:synthetic-password@host/bundle.js"
            stub_local_bundle_failure(Errno::ENOENT.new(server_bundle_path), bundle_path: server_bundle_path)

            message = bundle_load_error_message
            expect(message).not_to include("bundle-user")
            expect(message).not_to include("synthetic-password")
            expect(message).to include("http ://host/bundle.js")
          end
        end

        context "when a credential URL is authority-relative" do
          [
            ["valid userinfo", "//bundle-user:synthetic-password@host/bundle.js"],
            ["ambiguous userinfo", "//bundle-user:synthetic-password@credential-suffix@host/bundle.js"]
          ].each do |description, server_bundle_path|
            it "redacts #{description} even when the path is classified as a local bundle" do
              stub_local_bundle_failure(Errno::ENOENT.new(server_bundle_path), bundle_path: server_bundle_path)

              message = bundle_load_error_message
              expect(message).not_to include("bundle-user")
              expect(message).not_to include("synthetic-password")
              expect(message).not_to include("credential-suffix")
              expect(message).to include("//host/bundle.js")
            end
          end

          it "preserves an at sign in the path when the authority has no userinfo" do
            server_bundle_path = "//host/assets/component@2.js"
            stub_local_bundle_failure(Errno::ENOENT.new(server_bundle_path), bundle_path: server_bundle_path)

            expect(bundle_load_error_message).to include(server_bundle_path)
          end

          [" ", "URL="].each do |prefix|
            it "redacts credentials when #{prefix.inspect} precedes the authority marker" do
              server_bundle_path = "#{prefix}//bundle-user:synthetic-password@host/bundle.js"
              stub_local_bundle_failure(Errno::ENOENT.new(server_bundle_path), bundle_path: server_bundle_path)

              message = bundle_load_error_message
              expect(message).not_to include("bundle-user")
              expect(message).not_to include("synthetic-password")
              expect(message).to include("#{prefix}//host/bundle.js")
            end
          end
        end

        context "when malformed URL userinfo contains multiple at signs" do
          it "redacts the entire userinfo while retaining the host and path" do
            server_bundle_url =
              "http://bundle-user:password-prefix@password-suffix@bad host/webpack/development/server-bundle.js"
            stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

            message = bundle_load_error_message
            expect(message).not_to include("bundle-user")
            expect(message).not_to include("password-prefix")
            expect(message).not_to include("password-suffix")
            expect(message).to include("bad URI")
            expect(message).to include("bad host/webpack/development/server-bundle.js")
          end
        end

        context "when malformed URL userinfo contains an unescaped slash" do
          it "redacts every credential fragment while retaining the host and path" do
            server_bundle_url = "http://user:prefix/secret@host/path"
            stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

            message = bundle_load_error_message
            expect(message).not_to include("user")
            expect(message).not_to include("prefix")
            expect(message).not_to include("secret")
            expect(message).to include("bad URI")
            expect(message).to include("host/path")
          end
        end

        context "when malformed URL userinfo contains whitespace" do
          it "redacts the quoted URL from the URI error while retaining the host and path" do
            server_bundle_url = "http://user:prefix secret@host/path"
            stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

            message = bundle_load_error_message
            expect(message).not_to include("user")
            expect(message).not_to include("prefix")
            expect(message).not_to include("secret")
            expect(message).to include("bad URI")
            expect(message).to include("host/path")
          end
        end

        context "when whitespace makes malformed userinfo look like a valid host prefix" do
          it "does not protect the prefix quoted by the configured URL's URI error" do
            server_bundle_url = "http://synthetic-user secret-final@host/path"
            stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("secret-final")
            expect(message).to include("bad URI")
            expect(message).to include("host/path")
          end
        end

        context "when configured malformed userinfo has a delayed at sign" do
          [
            ["multiple intervening words", "http://synthetic-user secret-middle secret-final@host/path",
             %w[synthetic-user secret-middle secret-final]],
            ["a quote and whitespace", 'http://synthetic-user" secret-final@host/path',
             %w[synthetic-user secret-final]],
            ["a quote and multiple intervening words",
             'http://synthetic-user" secret-middle secret-final@host/path',
             %w[synthetic-user secret-middle secret-final]]
          ].each do |description, server_bundle_url, credential_fragments|
            it "redacts credentials after #{description}" do
              stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

              message = bundle_load_error_message
              credential_fragments.each { |fragment| expect(message).not_to include(fragment) }
              expect(message).to include("bad URI")
              expect(message).to include("host/path")
            end
          end
        end

        nested_scheme_cases = [
          ["a comma", "http://outer.test/first,http://synthetic-user:synthetic-secret@host/path"],
          ["a semicolon", "http://outer.test/first;http://synthetic-user:synthetic-secret@host/path"],
          ["a parenthesis", "http://outer.test/first(http://synthetic-user:synthetic-secret@host/path)"],
          ["a valid URL directly before a valid credential URL",
           "http://outer.test/firsthttp://synthetic-user:synthetic-secret@host/path"],
          ["mixed-case HTTP then HTTPS",
           "hTtP://outer.test/first;HtTpS://synthetic-user:synthetic-secret@host/path"],
          ["mixed-case HTTPS then HTTP",
           "HtTpS://outer.test/first;hTtP://synthetic-user:synthetic-secret@host/path"]
        ]

        context "when the configured URL contains another scheme without whitespace" do
          nested_scheme_cases.each do |description, server_bundle_url|
            it "sanitizes credentials after #{description}" do
              stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

              message = bundle_load_error_message
              expect(message).not_to include("synthetic-user")
              expect(message).not_to include("synthetic-secret")
              expect(message).not_to include("outer.test/first")
              expect(message).to include("host/path")
            end
          end
        end

        unresolved_prefix_cases = [
          ["an invalid prefix before a valid credential URL",
           "http://synthetic-user:nonnumeric-prefixhttp://synthetic-secret@host/path",
           %w[synthetic-user nonnumeric-prefix synthetic-secret]],
          ["a numeric-port prefix",
           "http://synthetic-user:123synthetic-prefixhttp://synthetic-secret@host/path",
           %w[synthetic-user 123synthetic-prefix synthetic-secret]],
          ["a slash in the invalid prefix",
           "http://synthetic-user:nonnumeric-prefix/synthetic-tailhttp://synthetic-secret@host/path",
           %w[synthetic-user nonnumeric-prefix synthetic-tail synthetic-secret]],
          ["a semicolon in the invalid prefix",
           "http://synthetic-user:nonnumeric-prefix;synthetic-tailhttp://synthetic-secret@host/path",
           %w[synthetic-user nonnumeric-prefix synthetic-tail synthetic-secret]]
        ]

        context "when the configured URL has an unresolved scheme before a credential URL" do
          unresolved_prefix_cases.each do |description, server_bundle_url, credential_fragments|
            it "fails closed across #{description}" do
              stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

              message = bundle_load_error_message
              credential_fragments.each { |fragment| expect(message).not_to include(fragment) }
              expect(message).to include("host/path")
            end
          end
        end

        context "when configured malformed userinfo spans line breaks" do
          [
            ["LF", "http://synthetic-user\nsynthetic-secret@host/path"],
            ["CR", "http://synthetic-user\rsynthetic-secret@host/path"],
            ["CRLF", "http://synthetic-user\r\nsynthetic-secret@host/path"],
            ["a quote and newline", "http://synthetic-user\"\nsynthetic-secret@host/path"]
          ].each do |description, server_bundle_url|
            it "fails closed across #{description} within the configured value" do
              stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

              message = bundle_load_error_message
              expect(message).not_to include("synthetic-user")
              expect(message).not_to include("synthetic-secret")
              expect(message).to include("host/path")
            end
          end
        end

        context "when a configured URL has an at sign only in its path" do
          it "preserves the URL because the configured value parses without userinfo" do
            server_bundle_url = "http://host/path@example"
            stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

            expect(bundle_load_error_message).to include(server_bundle_url)
          end
        end

        context "when non-URL text precedes a configured credential URL" do
          classifications = [["HTTP", true], ["local-path", false]]

          [
            ["a space", " ", "http"],
            ["a tab", "\t", "http"],
            ["a newline", "\n", "http"],
            ["a quote", '"', "http"],
            ["a label and mixed-case scheme", "URL=", "hTtPs"]
          ].each do |description, prefix, scheme|
            classifications.each do |classification, http_path|
              it "sanitizes #{description} through the #{classification} branch" do
                server_bundle_url = "#{prefix}#{scheme}://synthetic-user:synthetic-secret@host/path"
                sanitized_url = "#{prefix}#{scheme.downcase}://host/path"
                failure_message = "raw=#{server_bundle_url} inspected=#{server_bundle_url.inspect} " \
                                  "repeated=#{server_bundle_url}"

                if http_path
                  stub_http_bundle_failure(failure_message, bundle_url: server_bundle_url)
                else
                  stub_local_bundle_failure(failure_message, bundle_path: server_bundle_url)
                end

                message = bundle_load_error_message
                expect(message).not_to include("synthetic-user")
                expect(message).not_to include("synthetic-secret")
                expect(message).to include(sanitized_url)
              end
            end
          end
        end

        context "when malformed URL userinfo contains a literal double quote" do
          it "redacts the escaped URL from the URI error" do
            server_bundle_url = "http://synthetic-user:sec\"ret@host/path"
            stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("sec")
            expect(message).not_to include("ret")
            expect(message).to include("bad URI")
            expect(message).to include("host/path")
          end
        end

        context "when URI parsing raises another URI::Error subtype" do
          it "redacts configured credentials through the public entrypoint" do
            server_bundle_url = "http://synthetic-user:synthetic-secret@host/path"
            allow(URI).to receive(:parse).and_call_original
            allow(URI).to receive(:parse).with(server_bundle_url)
                                         .and_raise(URI::BadURIError, "bad URI for #{server_bundle_url}")
            stub_http_bundle_failure("connection failed", bundle_url: server_bundle_url)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("synthetic-secret")
            expect(message).to include("bad URI for http://host/path")
          end
        end

        context "when a local bundle path contains replacement metacharacters" do
          it "preserves them literally while redacting credentials from the load error" do
            server_bundle_path = %q(/tmp/\k<foo>-\1-\&-\0-literal\backslash/server-bundle.js)
            failure_message = "raw=#{server_bundle_path} inspected=#{server_bundle_path.inspect} " \
                              "credential=http://synthetic-user:synthetic-secret@host/path"
            stub_local_bundle_failure(failure_message, bundle_path: server_bundle_path)

            message = bundle_load_error_message
            expect(message).to include(server_bundle_path)
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("synthetic-secret")
            expect(message).to include("http://host/path")
            expect(message).to include("react_on_rails@shakacode.com")
          end
        end

        context "when a bundle-load failure embeds an unquoted malformed credential URL" do
          it "fails closed across whitespace in the credential" do
            failure_message = "Failure loading http://synthetic-user:prefix secret-final@host/path"
            stub_http_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("prefix")
            expect(message).not_to include("secret-final")
            expect(message).to include("Failure loading http://host/path")
          end
        end

        context "when a bundle-load failure embeds credentials in a non-HTTP URL" do
          %w[postgres redis ftp mongodb].each do |scheme|
            it "redacts credentials from the #{scheme} URL" do
              failure_message = "Failure loading #{scheme}://synthetic-user:synthetic-secret@host/path"
              stub_http_bundle_failure(failure_message)

              message = bundle_load_error_message
              expect(message).not_to include("synthetic-user")
              expect(message).not_to include("synthetic-secret")
              expect(message).to include("Failure loading #{scheme}://host/path")
            end
          end
        end

        context "when malformed userinfo looks like a valid host prefix in an ordinary error" do
          it "does not protect the prefix before the whitespace-delimited credential suffix" do
            failure_message = "Failure loading http://synthetic-user:123 secret-final@host/path"
            stub_http_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("123")
            expect(message).not_to include("secret-final")
            expect(message).to include("Failure loading http://host/path")
          end
        end

        context "when an ordinary error has a delayed credential at sign" do
          [
            ["multiple intervening words", "http://synthetic-user secret-middle secret-final@host/path",
             %w[synthetic-user secret-middle secret-final]],
            ["a quote and whitespace", 'http://synthetic-user" secret-final@host/path',
             %w[synthetic-user secret-final]],
            ["a quote and multiple intervening words",
             'http://synthetic-user" secret-middle secret-final@host/path',
             %w[synthetic-user secret-middle secret-final]]
          ].each do |description, malformed_url, credential_fragments|
            it "redacts credentials after #{description}" do
              failure_message = "Failure loading #{malformed_url}"
              stub_http_bundle_failure(failure_message)

              message = bundle_load_error_message
              credential_fragments.each { |fragment| expect(message).not_to include(fragment) }
              expect(message).to include("Failure loading http://host/path")
            end
          end
        end

        context "when malformed userinfo in an ordinary error spans line breaks" do
          [
            ["LF", "http://synthetic-user\nsynthetic-secret@host/path"],
            ["CR", "http://synthetic-user\rsynthetic-secret@host/path"],
            ["CRLF", "http://synthetic-user\r\nsynthetic-secret@host/path"],
            ["a quote and LF", "http://synthetic-user\"\nsynthetic-secret@host/path"]
          ].each do |description, malformed_url|
            it "fails closed across #{description}" do
              failure_message = "Failure loading #{malformed_url}"
              stub_local_bundle_failure(failure_message)

              message = bundle_load_error_message
              expect(message).not_to include("synthetic-user")
              expect(message).not_to include("synthetic-secret")
              expect(message).to include("Failure loading http://host/path")
            end
          end
        end

        context "when an ordinary error contains another scheme without whitespace" do
          nested_scheme_cases.each do |description, nested_urls|
            it "sanitizes credentials after #{description}" do
              failure_message = "Failure loading #{nested_urls}"
              stub_http_bundle_failure(failure_message)

              message = bundle_load_error_message
              expect(message).not_to include("synthetic-user")
              expect(message).not_to include("synthetic-secret")
              expect(message).to include("outer.test/first")
              expect(message).to include("host/path")
            end
          end
        end

        context "when an ordinary error has an unresolved scheme before a credential URL" do
          unresolved_prefix_cases.each do |description, nested_urls, credential_fragments|
            it "fails closed across #{description}" do
              failure_message = "Failure loading #{nested_urls}"
              stub_http_bundle_failure(failure_message)

              message = bundle_load_error_message
              credential_fragments.each { |fragment| expect(message).not_to include(fragment) }
              expect(message).to include("Failure loading http://host/path")
            end
          end
        end

        context "when an invalid credential URL is followed by a valid URL" do
          it "redacts the credential and preserves the later URL" do
            failure_message = "Failure loading http://synthetic-user secret-final@host/path " \
                              "http://healthy-host/path"
            stub_http_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("secret-final")
            expect(message).to include("Failure loading http://host/path http://healthy-host/path")
          end
        end

        context "when an ordinary error quotes malformed userinfo across whitespace" do
          it "redacts the quoted credential while retaining the host and path" do
            failure_message = 'Failure loading "http://synthetic-user secret-final@host/path"'
            stub_http_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("secret-final")
            expect(message).to include('Failure loading "http://host/path"')
          end
        end

        context "when a quote truncates a malformed credential URL token" do
          it "does not protect the valid-looking prefix before the double quote" do
            failure_message = 'Failure loading http://synthetic-user"secret-final@host/path'
            stub_http_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("secret-final")
            expect(message).to include("Failure loading http://host/path")
          end

          it "does not protect the valid-looking prefix before the single quote" do
            failure_message = "Failure loading http://synthetic-user'secret-final@host/path"
            stub_http_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("secret-final")
            expect(message).to include("Failure loading http://host/path")
          end
        end

        context "when a bundle-load failure embeds a valid URL with an at sign in its path" do
          it "preserves the URL because it has no userinfo" do
            failure_message = "Failure loading http://host/path@example"
            stub_http_bundle_failure(failure_message)

            expect(bundle_load_error_message).to include(failure_message)
          end
        end

        context "when a bundle-load failure contains two valid URLs" do
          it "preserves both URLs, including an at sign in the second URL's path" do
            failure_message = "Failure loading http://first-host/path http://second-host/path@example"
            stub_http_bundle_failure(failure_message)

            expect(bundle_load_error_message).to include(failure_message)
          end
        end

        context "when a line boundary precedes an ambiguous email at sign" do
          [["LF", "\n"], ["CR", "\r"], ["CRLF", "\r\n"]].each do |description, boundary|
            it "fails closed across #{description}" do
              failure_message = "Failure loading http://host/path#{boundary}contact dev@example.com"
              stub_http_bundle_failure(failure_message)

              message = bundle_load_error_message
              expect(message).not_to include("host/path")
              expect(message).not_to include("contact dev")
              expect(message).to include("Failure loading http://example.com")
            end
          end
        end

        context "when multiline error text contains a later URL scheme" do
          it "redacts malformed multiline userinfo without consuming the later URL" do
            failure_message = "Failure loading http://synthetic-user\nsynthetic-secret@host/path\n" \
                              "hTtPs://healthy-host/path@example"
            stub_local_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("synthetic-secret")
            expect(message).to include("Failure loading http://host/path\nhTtPs://healthy-host/path@example")
          end

          it "fails closed before the later scheme while preserving that separate URL" do
            failure_message = "Failure loading http://first-host/path\ncontact dev@example.com\n" \
                              "HTTP://second-host/path"
            stub_local_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("first-host/path")
            expect(message).not_to include("contact dev")
            expect(message).to include("Failure loading http://example.com\nHTTP://second-host/path")
          end

          it "discards an unresolved multiline region before sanitizing the next credential URL" do
            failure_message = "Failure loading http://synthetic-user:nonnumeric-prefix\nsynthetic-tail " \
                              "HtTpS://synthetic-secret@host/path"
            stub_local_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("nonnumeric-prefix")
            expect(message).not_to include("synthetic-tail")
            expect(message).not_to include("synthetic-secret")
            expect(message).to include("Failure loading https://host/path")
          end
        end

        context "when a valid-looking URL is followed by prose containing an email address" do
          it "fails closed because no structural boundary separates the later at sign" do
            failure_message = "Failure loading http://host/path; contact dev@example.com"
            stub_http_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("host/path")
            expect(message).not_to include("contact dev")
            expect(message).to include("Failure loading http://example.com")
          end
        end

        context "when a bundle-load failure contains authority-relative credentials" do
          it "redacts the credentials while retaining the host and path" do
            failure_message = "Failure loading //synthetic-user:synthetic-secret@host/path"
            stub_http_bundle_failure(failure_message)

            message = bundle_load_error_message
            expect(message).not_to include("synthetic-user")
            expect(message).not_to include("synthetic-secret")
            expect(message).to include("Failure loading //host/path")
          end

          [
            ["whitespace", "//synthetic-user synthetic-secret@host/path"],
            ["a quote", '//synthetic-user" synthetic-secret@host/path'],
            ["an LF line break", "//synthetic-user\nsynthetic-secret@host/path"],
            ["a CRLF line break", "//synthetic-user\r\nsynthetic-secret@host/path"]
          ].each do |description, malformed_url|
            it "fails closed when authority-relative userinfo spans #{description}" do
              stub_local_bundle_failure("Failure loading #{malformed_url}")

              message = bundle_load_error_message
              expect(message).not_to include("synthetic-user")
              expect(message).not_to include("synthetic-secret")
              expect(message).to include("Failure loading //host/path")
            end
          end
        end

        context "when a bundle-load failure contains non-URL double-slash text" do
          it "preserves the arbitrary message text" do
            failure_message = "// contact dev@example"
            stub_http_bundle_failure(failure_message)

            expect(bundle_load_error_message).to include(failure_message)
          end
        end

        # read_bundle_js_code also serves the local (non-HTTP) bundle path, where
        # server_bundle_js_file is a plain filesystem path rather than a URL.
        # sanitized_renderer_url must pass such paths through unchanged (no embedded userinfo to
        # strip) so this fix doesn't regress the diagnostic message for the far more common
        # local-file configuration.
        context "when the local (non-HTTP) bundle file cannot be read" do
          it "still names the configured file path in the raised error message" do
            server_bundle_path = "/app/public/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_path,
              server_bundle_path_is_http?: false
            )
            allow(File).to receive(:read).with(server_bundle_path).and_raise(
              Errno::ENOENT, server_bundle_path
            )

            expect do
              described_class.read_bundle_js_code
            end.to raise_error(ReactOnRails::ServerBundleLoadError) { |error|
              expect(error.message).to include(server_bundle_path)
              expect(error.message).to include("cannot be read")
            }
          end
        end

        # See issue #4584: the charset was assumed to always be present in the exact form
        # "; charset=..." rather than honored from whatever the response actually declares.
        #
        # This must actually transcode the bytes to UTF-8, not merely relabel them: ExecJS's
        # underlying JS runtime parses source as UTF-8, so a body only tagged with its declared
        # encoding (rather than converted) would have its non-ASCII bytes silently corrupted the
        # moment the runtime re-interprets them as UTF-8. Asserting only the string's `#encoding`
        # after a relabel-only fix would pass while still shipping corrupted bytes to the JS
        # engine, so this asserts the actual returned bytes decode correctly.
        context "when the HTTP-served bundle declares a non-UTF-8 charset" do
          it "transcodes the body from the declared charset to UTF-8, preserving non-ASCII content" do
            server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            # "// café" encoded as ISO-8859-1 (0xE9 is not a valid standalone UTF-8 byte).
            latin1_body = "// caf\xE9\nvar x = 1;".dup.force_encoding(Encoding::ASCII_8BIT)

            ok_response = Net::HTTPOK.new("1.1", "200", "OK")
            # A quoted charset value is valid per RFC 7231's quoted-string parameter syntax.
            # The pre-fix regex captured the literal value including the quote characters and
            # passed it straight to String#force_encoding, raising
            # `ArgumentError: unknown encoding name - "ISO-8859-1"` instead of decoding.
            ok_response["content-type"] = 'application/javascript; charset="ISO-8859-1"'
            ok_response.instance_variable_set(:@read, true)
            ok_response.instance_variable_set(:@body, latin1_body)

            allow(Net::HTTP).to receive(:get_response).and_return(ok_response)

            result = described_class.read_bundle_js_code

            # The SUT's own return value must already be valid, transcoded UTF-8 — not ISO-8859-1
            # bytes that happen to be convertible if a caller separately re-encodes them.
            expect(result.encoding).to eq(Encoding::UTF_8)
            expect(result.valid_encoding?).to be(true)
            expect(result).to eq("// café\nvar x = 1;")
          end
        end

        # String#encode is a no-op — it does not validate — when the source encoding already
        # equals the destination (UTF-8). charset_from_content_type returns UTF-8 for the three
        # "same-encoding" cases below (no Content-Type header, no charset parameter, and an
        # explicit charset=utf-8), so `.encode(Encoding::UTF_8)` alone would silently let an
        # invalid byte through unchanged on each of them. A genuine cross-encoding transcode can
        # reject malformed input only when the source encoding has invalid byte sequences of its
        # own (such as Shift_JIS). Each of these three specs uses a body containing an invalid
        # standalone byte (0xE9) to prove the explicit valid_encoding? check (not `encode` alone) is
        # what catches it.
        context "when the HTTP-served bundle response has no Content-Type header and the body is not valid UTF-8" do
          it "raises instead of silently passing corrupt bytes through" do
            server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            invalid_utf8_body = "// caf\xE9\nvar x = 1;".dup.force_encoding(Encoding::ASCII_8BIT)

            ok_response = Net::HTTPOK.new("1.1", "200", "OK")
            ok_response.instance_variable_set(:@read, true)
            ok_response.instance_variable_set(:@body, invalid_utf8_body)

            allow(Net::HTTP).to receive(:get_response).and_return(ok_response)

            expect do
              described_class.read_bundle_js_code
            end.to raise_error(ReactOnRails::ServerBundleLoadError) { |error|
              expect(error.message).to include(server_bundle_url)
              expect(error.message).to include("not valid UTF-8")
            }
          end
        end

        context "when the HTTP-served bundle response has a Content-Type with no charset parameter " \
                "and the body is not valid UTF-8" do
          it "raises instead of silently passing corrupt bytes through" do
            server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            invalid_utf8_body = "// caf\xE9\nvar x = 1;".dup.force_encoding(Encoding::ASCII_8BIT)

            ok_response = Net::HTTPOK.new("1.1", "200", "OK")
            ok_response["content-type"] = "application/javascript"
            ok_response.instance_variable_set(:@read, true)
            ok_response.instance_variable_set(:@body, invalid_utf8_body)

            allow(Net::HTTP).to receive(:get_response).and_return(ok_response)

            expect do
              described_class.read_bundle_js_code
            end.to raise_error(ReactOnRails::ServerBundleLoadError) { |error|
              expect(error.message).to include(server_bundle_url)
              expect(error.message).to include("not valid UTF-8")
            }
          end
        end

        context "when the HTTP-served bundle declares charset=utf-8 explicitly and the body is not valid UTF-8" do
          it "raises instead of silently passing corrupt bytes through" do
            server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            invalid_utf8_body = "// caf\xE9\nvar x = 1;".dup.force_encoding(Encoding::ASCII_8BIT)

            ok_response = Net::HTTPOK.new("1.1", "200", "OK")
            ok_response["content-type"] = "application/javascript; charset=utf-8"
            ok_response.instance_variable_set(:@read, true)
            ok_response.instance_variable_set(:@body, invalid_utf8_body)

            allow(Net::HTTP).to receive(:get_response).and_return(ok_response)

            expect do
              described_class.read_bundle_js_code
            end.to raise_error(ReactOnRails::ServerBundleLoadError) { |error|
              expect(error.message).to include(server_bundle_url)
              expect(error.message).to include("not valid UTF-8")
            }
          end
        end

        context "when the HTTP-served bundle declares a charset Ruby does not recognize" do
          it "falls back to UTF-8 instead of raising" do
            server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            ok_response = Net::HTTPOK.new("1.1", "200", "OK")
            ok_response["content-type"] = "application/javascript; charset=unknown-charset"
            ok_response.instance_variable_set(:@read, true)
            ok_response.instance_variable_set(:@body, "var x = 1;")

            allow(Net::HTTP).to receive(:get_response).and_return(ok_response)

            result = described_class.read_bundle_js_code

            expect(result).to eq("var x = 1;")
            expect(result.encoding).to eq(Encoding::UTF_8)
          end
        end

        # Acceptance criteria (#4584): a successful response with a missing/blank charset,
        # or a missing Content-Type header entirely, must not raise — it should fall back to
        # a safe default encoding rather than blowing up on a nil charset match.
        context "when the HTTP-served bundle response has no Content-Type header" do
          it "falls back to UTF-8 instead of raising" do
            server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            ok_response = Net::HTTPOK.new("1.1", "200", "OK")
            ok_response.instance_variable_set(:@read, true)
            ok_response.instance_variable_set(:@body, "var x = 1;")

            allow(Net::HTTP).to receive(:get_response).and_return(ok_response)

            result = described_class.read_bundle_js_code

            expect(result).to eq("var x = 1;")
            expect(result.encoding).to eq(Encoding::UTF_8)
          end
        end

        context "when the HTTP-served bundle response has a Content-Type with no charset parameter" do
          it "falls back to UTF-8 instead of raising" do
            server_bundle_url = "http://localhost:3035/webpack/development/server-bundle.js"

            allow(ReactOnRails::Utils).to receive_messages(
              server_bundle_js_file_path: server_bundle_url,
              server_bundle_path_is_http?: true
            )

            ok_response = Net::HTTPOK.new("1.1", "200", "OK")
            ok_response["content-type"] = "application/javascript"
            ok_response.instance_variable_set(:@read, true)
            ok_response.instance_variable_set(:@body, "var x = 1;")

            allow(Net::HTTP).to receive(:get_response).and_return(ok_response)

            result = described_class.read_bundle_js_code

            expect(result).to eq("var x = 1;")
            expect(result.encoding).to eq(Encoding::UTF_8)
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
