# frozen_string_literal: true

require_relative "spec_helper"
require "fileutils"
require "tmpdir"

module ReactOnRails
  RSpec.describe TypeScriptResponseTypes, ".generate filesystem races" do
    before { described_class.reset! }

    after { described_class.reset! }

    it "does not remove concurrently populated output directories when the final write fails" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        output_path = "generated/nested/rails_response_types.d.ts"
        generated_root = File.join(dir, "generated")
        generated_path = File.join(dir, output_path)
        concurrent_file = File.join(generated_root, "keep.txt")
        allow(FileUtils).to receive(:mv).and_call_original
        allow(FileUtils).to receive(:mv).with(anything, generated_path) do
          FileUtils.mkdir_p(generated_root)
          File.write(concurrent_file, "keep")
          raise Errno::ENOSPC
        end

        expect do
          described_class.generate(output_path:)
        end.to raise_error(Errno::ENOSPC)
        expect(File.read(concurrent_file)).to eq("keep")
      end
    end

    it "does not remove concurrently created empty output directories when the final write fails" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        output_path = "generated/nested/rails_response_types.d.ts"
        generated_root = File.join(dir, "generated")
        nested_dir = File.join(generated_root, "nested")
        generated_path = File.join(dir, output_path)

        allow(Dir).to receive(:mkdir).and_wrap_original do |original_method, directory, *args|
          original_method.call(directory, *args)
          raise Errno::EEXIST if directory == nested_dir
        end
        allow(FileUtils).to receive(:mv).and_call_original
        allow(FileUtils).to receive(:mv).with(anything, generated_path).and_raise(Errno::ENOSPC)

        expect do
          described_class.generate(output_path:)
        end.to raise_error(Errno::ENOSPC)
        expect(File).to exist(nested_dir)
      end
    end

    it "rejects output parent symlink swaps before creating the generated file" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        Dir.mktmpdir do |outside_dir|
          allow(Rails).to receive(:root).and_return(Pathname.new(dir))
          output_path = "generated/escape/rails_response_types.d.ts"
          output_dir = File.join(dir, "generated")
          escape_link = File.join(output_dir, "escape")
          escaped_path = File.join(outside_dir, "rails_response_types.d.ts")

          allow(Dir).to receive(:mkdir).and_call_original
          allow(Dir).to receive(:mkdir).with(escape_link) do
            File.symlink(outside_dir, escape_link)
            raise Errno::EEXIST
          end

          expect do
            described_class.generate(output_path:)
          end.to raise_error(ReactOnRails::Error, /must be inside Rails\.root/)
          expect(File).not_to exist(escaped_path)
          expect(File).to be_symlink(escape_link)
        end
      end
    end

    it "does not create output directories through a swapped parent symlink" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        Dir.mktmpdir do |outside_dir|
          allow(Rails).to receive(:root).and_return(Pathname.new(dir))
          output_path = "generated/escape/rails_response_types.d.ts"
          output_dir = File.join(dir, "generated")
          escaped_dir = File.join(outside_dir, "escape")
          escaped_file = File.join(escaped_dir, "keep.txt")

          allow(Dir).to receive(:mkdir).and_call_original
          allow(Dir).to receive(:mkdir).with(output_dir) do
            File.symlink(outside_dir, output_dir)
            raise Errno::EEXIST
          end

          expect do
            described_class.generate(output_path:)
          end.to raise_error(ReactOnRails::Error, /must be inside Rails\.root/)
          expect(File).not_to exist(escaped_file)
          expect(File).not_to exist(escaped_dir)
          expect(File).to be_symlink(output_dir)
        end
      end
    end
  end
end
