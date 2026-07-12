# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  describe PrerenderError do
    subject(:expected_error) do
      described_class.new(
        component_name: input_error_info[:component_name],
        err: input_error_info[:err],
        props: input_error_info[:props],
        js_code: input_error_info[:js_code],
        console_messages: input_error_info[:console_messages]
      )
    end

    let(:err) do
      result = nil
      begin
        raise "Some Error"
      rescue StandardError => e
        result = e
      end
      result
    end

    let(:input_error_info) do
      {
        component_name: "component_name",
        err:,
        props: { a: 1, b: 2 },
        js_code: "console.log('foobar')",
        console_messages: "console_messages"
      }
    end

    let(:expected_error_info) do
      input_error_info.merge(props: "[REDACTED]", js_code: "[REDACTED]")
    end

    let(:sensitive_props) { { email: "person@example.com", access_token: "top-secret" } }
    let(:sensitive_js_code) { "const token = 'top-secret';" }

    describe ".to_honey_badger_context" do
      it "returns the correct context" do
        expect(expected_error.to_honeybadger_context).to eq(expected_error_info)
      end
    end

    describe ".raven_context" do
      it "returns the correct context" do
        expect(expected_error.raven_context).to eq(expected_error_info)
      end
    end

    it "does not retain raw props or generated JavaScript on the exception" do
      expect(expected_error.props).to eq("[REDACTED]")
      expect(expected_error.js_code).to eq("[REDACTED]")
    end

    describe "error message formatting" do
      it "does not include props or generated JavaScript" do
        error = described_class.new(props: sensitive_props, js_code: sensitive_js_code)

        expect(error.message).to include("[REDACTED]")
        expect(error.message).not_to include("person@example.com", "top-secret")
      end

      context "when FULL_TEXT_ERRORS is true" do
        before { ENV["FULL_TEXT_ERRORS"] = "true" }
        after { ENV["FULL_TEXT_ERRORS"] = nil }

        it "shows the full backtrace" do
          message = expected_error.message
          expect(message).to include(err.inspect)
          expect(message).to include(err.backtrace.join("\n"))
          expect(message).not_to include("The rest of the backtrace is hidden")
        end
      end

      context "when FULL_TEXT_ERRORS is not set" do
        before { ENV["FULL_TEXT_ERRORS"] = nil }

        it "shows truncated backtrace with notice" do
          message = expected_error.message
          expect(message).to include(err.inspect)
          # Ruby version compatibility: match any backtrace reference to the test file
          backtrace_pattern = /prender_error_spec\.rb:\d+:in ['`]block \(\d+ levels\) in <module:ReactOnRails>['`]/
          expect(message).to match(backtrace_pattern)
          expect(message).to include("💡 Tip: Set FULL_TEXT_ERRORS=true to see the full backtrace")
        end
      end
    end
  end
end
