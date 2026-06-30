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

    it "writes the generated declaration file with normal readable permissions" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        output_path = "generated/rails_response_types.d.ts"
        generated_path = File.join(dir, output_path)

        described_class.generate(output_path:)

        expect(File.stat(generated_path).mode & 0o777).to eq(0o666 & ~File.umask)
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

    it "rejects existing directories as output paths" do
      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })
        output_dir = File.join(dir, "generated")
        FileUtils.mkdir_p(output_dir)

        expect do
          described_class.generate(output_path: "generated")
        end.to raise_error(ReactOnRails::Error, /must be inside Rails\.root/)
        expect(Dir.children(output_dir)).to be_empty
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

    it "wraps invalid path arguments in ReactOnRails::Error" do
      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))

        expect do
          described_class.generate(output_path: "generated/\0rails_response_types.d.ts")
        end.to raise_error(ReactOnRails::Error, /must be inside Rails\.root/)
      end
    end

    it "allows output paths under the real Rails.root when Rails.root is a symlink" do
      Dir.mktmpdir do |dir|
        real_root = File.join(dir, "real-root")
        linked_root = File.join(dir, "linked-root")
        FileUtils.mkdir_p(File.join(real_root, "generated"))
        File.symlink(real_root, linked_root)
        allow(Rails).to receive(:root).and_return(Pathname.new(linked_root))
        described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

        output_path = File.join(real_root, "generated/rails_response_types.d.ts")

        expect(described_class.generate(output_path:)).to eq(output_path)
        expect(File.read(output_path)).to include("export interface HealthResponse")
      end
    end

    it "does not create the output directory when generation fails" do
      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        described_class.define_response(
          "health.show",
          type_name: "HealthResponse",
          fields: { ok: { raw: "string //" } }
        )

        output_dir = File.join(dir, "generated")

        expect do
          described_class.generate(output_path: "generated/rails_response_types.d.ts")
        end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
        expect(File).not_to exist(output_dir)
      end
    end

    it "removes a freshly created output directory when the final write fails" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        output_path = "generated/rails_response_types.d.ts"
        output_dir = File.join(dir, "generated")
        generated_path = File.join(dir, output_path)
        allow(FileUtils).to receive(:mv).and_call_original
        allow(FileUtils).to receive(:mv).with(anything, generated_path).and_raise(Errno::ENOSPC)

        expect do
          described_class.generate(output_path:)
        end.to raise_error(Errno::ENOSPC)
        expect(File).not_to exist(output_dir)
      end
    end

    it "removes the highest newly created output ancestor when a nested final write fails" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        FileUtils.mkdir_p(File.join(dir, "existing"))
        output_path = "existing/generated/nested/rails_response_types.d.ts"
        generated_root = File.join(dir, "existing/generated")
        generated_path = File.join(dir, output_path)
        allow(FileUtils).to receive(:mv).and_call_original
        allow(FileUtils).to receive(:mv).with(anything, generated_path).and_raise(Errno::ENOSPC)

        expect do
          described_class.generate(output_path:)
        end.to raise_error(Errno::ENOSPC)
        expect(File).to exist(File.join(dir, "existing"))
        expect(File).not_to exist(generated_root)
      end
    end

    it "preserves the original write error when tempfile cleanup fails" do
      described_class.define_response("health.show", type_name: "HealthResponse", fields: { ok: :boolean })

      Dir.mktmpdir do |dir|
        allow(Rails).to receive(:root).and_return(Pathname.new(dir))
        output_path = "generated/rails_response_types.d.ts"
        output_dir = File.join(dir, "generated")
        generated_path = File.join(dir, output_path)
        allow(FileUtils).to receive(:mv).and_call_original
        allow(FileUtils).to receive(:mv).with(anything, generated_path).and_raise(Errno::ENOSPC)
        allow(Tempfile).to receive(:new).and_wrap_original do |original_method, *args|
          original_method.call(*args).tap do |tempfile|
            allow(tempfile).to receive(:unlink).and_raise(Errno::EACCES)
          end
        end

        expect do
          described_class.generate(output_path:)
        end.to raise_error(Errno::ENOSPC)
        expect(File).to exist(output_dir)
        expect(File).not_to exist(generated_path)
      end
    end
  end
end
