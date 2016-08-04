require_relative "spec_helper"
require "react_on_rails/assets_precompile"

require "tmpdir"
require "tempfile"

module ReactOnRails
  RSpec.describe AssetsPrecompile do
    let(:assets_path) { Pathname.new(Dir.mktmpdir) }

    describe "#symlink_file" do
      it "creates a proper symlink" do
        filename = File.basename(Tempfile.new("tempfile", assets_path))
        digest_filename = "#{filename}_digest"
        AssetsPrecompile.new(assets_path: assets_path)
                        .symlink_file(filename, digest_filename)

        expect(assets_path.join(digest_filename).lstat.symlink?).to be true
        expect(File.identical?(assets_path.join(filename),
                               assets_path.join(digest_filename))).to be true
      end

      it "creates a relative symlink" do
        filename = File.basename(Tempfile.new("tempfile", assets_path))
        digest_filename = "#{filename}_digest"
        AssetsPrecompile.new(assets_path: assets_path)
                        .symlink_file(filename, digest_filename)

        expect(File.readlink(assets_path.join(digest_filename)).to_s).to eq(filename)
        expect(File.readlink(assets_path.join(digest_filename)).to_s)
          .not_to eq(File.expand_path(assets_path.join(filename)).to_s)
      end

      it "creates a proper symlink with spaces in path" do
        filename = File.basename(Tempfile.new("temp file", assets_path))
        digest_filename = "#{filename} digest"
        AssetsPrecompile.new(assets_path: assets_path)
                        .symlink_file(filename, digest_filename)

        expect(assets_path.join(digest_filename).lstat.symlink?).to be true
        expect(File.identical?(assets_path.join(filename),
                               assets_path.join(digest_filename))).to be true
      end

      it "creates a proper symlink when nested" do
        Dir.mkdir assets_path.join("images")
        filename = "images/" + File.basename(Tempfile.new("tempfile",
                                                          assets_path.join("images")))
        digest_filename = "#{filename}_digest"
        AssetsPrecompile.new(assets_path: assets_path)
                        .symlink_file(filename, digest_filename)

        expect(assets_path.join(digest_filename).lstat.symlink?).to be true
        expect(File.identical?(assets_path.join(filename),
                               assets_path.join(digest_filename))).to be true
      end
    end

    describe "symlink_non_digested_assets" do
      let(:digest_filename) { "alfa.12345.js" }
      let(:nondigest_filename) { "alfa.js" }

      let(:checker) do
        f = File.new(assets_path.join("manifest-alfa.json"), "w")
        f.write("{\"assets\":{\"#{nondigest_filename}\": \"#{digest_filename}\"}}")
        f.close

        AssetsPrecompile.new(assets_path: assets_path,
                             symlink_non_digested_assets_regex: Regexp.new('.*\.js$'))
      end

      context "correct nondigest filename" do
        it "creates valid symlink" do
          FileUtils.touch assets_path.join(digest_filename)
          checker.symlink_non_digested_assets

          expect(assets_path.join(nondigest_filename).lstat.symlink?).to be true
          expect(File.identical?(assets_path.join(nondigest_filename),
                                 assets_path.join(digest_filename))).to be true
        end
      end

      context "zipped nondigest filename" do
        it "creates valid symlink" do
          FileUtils.touch assets_path.join("#{digest_filename}.gz")
          checker.symlink_non_digested_assets

          expect(assets_path.join("#{nondigest_filename}.gz").lstat.symlink?).to be true
          expect(File.identical?(assets_path.join("#{nondigest_filename}.gz"),
                                 assets_path.join("#{digest_filename}.gz"))).to be true
        end
      end

      context "wrong nondigest filename" do
        it "should not create symlink" do
          FileUtils.touch assets_path.join("alfa.12345.jsx")
          checker.symlink_non_digested_assets

          expect(assets_path.join("alfa.jsx")).not_to exist
        end
      end
    end

    describe "delete_broken_symlinks" do
      it "deletes a broken symlink" do
        filename = File.basename(Tempfile.new("tempfile", assets_path))
        digest_filename = "#{filename}_digest"

        a = AssetsPrecompile.new(assets_path: assets_path)
        a.symlink_file(filename, digest_filename)
        File.unlink(assets_path.join(filename))
        a.delete_broken_symlinks

        expect(assets_path.join(filename)).not_to exist
        expect(assets_path.join(digest_filename)).not_to exist
      end
    end

    describe "clobber" do
      it "deletes files in ReactOnRails.configuration.generated_assets_dir" do
        allow(Rails).to receive(:root).and_return(Pathname.new(Dir.mktmpdir))

        generated_assets_dir  = "generated_dir"
        generated_assets_path = Rails.root.join(generated_assets_dir)
        Dir.mkdir generated_assets_path

        filepath = Pathname.new(Tempfile.new("tempfile", generated_assets_path))

        AssetsPrecompile.new(assets_path: assets_path,
                             generated_assets_dir: generated_assets_dir).clobber

        expect(filepath).not_to exist
      end
    end
  end
end
