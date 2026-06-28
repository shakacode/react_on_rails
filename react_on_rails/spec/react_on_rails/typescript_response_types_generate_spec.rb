# frozen_string_literal: true

require_relative "spec_helper"
require "tmpdir"

module ReactOnRails
  RSpec.describe TypeScriptResponseTypes, ".generate" do
    before { described_class.reset! }

    after { described_class.reset! }

    it "writes the generated declaration file inside Rails.root" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        output_path = "generated/rails_response_types.d.ts"
        generated_path = File.join(dir, output_path)

        expect(described_class.generate(output_path:)).to eq(generated_path)
        expect(File.read(generated_path)).to include("export interface HealthResponse")
      end
    end

    it "rejects output paths outside Rails.root" do
      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))

        expect do
          described_class.generate(output_path: "../outside/rails_response_types.d.ts")
        end.to raise_error(ReactOnRails::Error, /must be inside Rails\.root/)
      end
    end
  end
end
