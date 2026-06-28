# frozen_string_literal: true

require_relative "spec_helper"
require "fileutils"
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

    it "rejects Rails.root itself as an output path" do
      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))

        expect do
          described_class.generate(output_path: dir)
        end.to raise_error(ReactOnRails::Error, /must be inside Rails\.root/)
      end
    end

    it "rejects output paths that escape Rails.root through a symlink" do
      Dir.mktmpdir do |dir|
        Dir.mktmpdir do |outside_dir|
          allow(Rails).to receive(:root).and_return(Pathname.new(dir))
          FileUtils.mkdir_p(File.join(dir, "generated"))
          File.symlink(outside_dir, File.join(dir, "generated/escape"))

          expect do
            described_class.generate(output_path: "generated/escape/rails_response_types.d.ts")
          end.to raise_error(ReactOnRails::Error, /must be inside Rails\.root/)
          expect(File).not_to exist(File.join(outside_dir, "rails_response_types.d.ts"))
        end
      end
    end
  end
end
