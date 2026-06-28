# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe TypeScriptResponseTypes, "thread safety" do
    before { described_class.reset! }

    after { described_class.reset! }

    it "does not reset the registry while a registration is in progress" do
      registry = described_class.registry
      registration_started = Queue.new
      release_registration = Queue.new
      reset_finished = Queue.new

      allow(registry).to receive(:define_type) do
        registration_started << true
        release_registration.pop
      end

      registration_thread = Thread.new do
        described_class.define_type("Project", fields: {})
      end
      registration_started.pop

      reset_thread = Thread.new do
        described_class.reset!
        reset_finished << true
      end

      20.times do
        break unless reset_finished.empty?

        Thread.pass
        sleep 0.001
      end
      expect(reset_finished).to be_empty

      release_registration << true
      registration_thread.join
      reset_thread.join
      expect(reset_finished.pop(true)).to be(true)
    end
  end
end
