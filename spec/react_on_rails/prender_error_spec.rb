# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  describe PrerenderError do
    let(:err) do
      result = nil
      begin
        raise "Some Error"
      rescue StandardError => e
        result = e
      end
      result
    end

    let(:expected_error_info) do
      {
        component_name: "component_name",
        err: err,
        props: { a: 1, b: 2 },
        js_code: "console.log('foobar')",
        console_messages: "console_messages"
      }
    end

    subject do
      PrerenderError.new(
        component_name: expected_error_info[:component_name],
        err: expected_error_info[:err],
        props: expected_error_info[:props],
        js_code: expected_error_info[:js_code],
        console_messages: expected_error_info[:console_messages]
      )
    end

    describe ".to_honey_badger_context" do
      it "returns the correct context" do
        expect(subject.to_honeybadger_context).to eq(expected_error_info)
      end
    end

    describe ".raven_context" do
      it "returns the correct context" do
        expect(subject.raven_context).to eq(expected_error_info)
      end
    end
  end
end
