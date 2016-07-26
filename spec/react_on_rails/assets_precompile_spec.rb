require_relative "spec_helper"
require "react_on_rails/assets_precompile"

require "tmpdir"
require "tempfile"

module ReactOnRails
  RSpec.describe AssetsPrecompile do

    assets_path = Pathname.new(Dir.mktmpdir)
    
    describe "symlink_file" do
      it "creates a proper symlink" do
        filename = File.basename(Tempfile.new("tempfile",assets_path))
        digest_filename = "#{filename}_digest"
        AssetsPrecompile.new(assets_path: assets_path).
              symlink_file(filename,digest_filename)
        
        expect(assets_path.join(digest_filename).lstat.symlink?).to be true
        expect(File.identical?( assets_path.join(filename),
                                assets_path.join(digest_filename))).to be true
      end
      
      it "creates a proper symlink if nested" do
        Dir.mkdir(assets_path.join("images"))
        filename = "images/" + File.basename(Tempfile.new("tempfile",
                  assets_path.join("images")))
        digest_filename = "#{filename}_digest"
        AssetsPrecompile.new(assets_path: assets_path).
              symlink_file(filename,digest_filename)
        
        expect(assets_path.join(digest_filename).lstat.symlink?).to be true
        expect(File.identical?( assets_path.join(filename),
                                assets_path.join(digest_filename))).to be true
      end
    end

    describe "symlink_non_digested_assets" do
      it "creates the necessary symlinks" do
        manifest_filename = "manifest-alfa.json" 
        digest_filename = "alfa.12345.js"
        nondigest_filename = "alfa.js"
        digest_bad_filename = "alfa.12345.jsx"
        nondigest_bad_filename = "alfa.jsx"
      
        Dir.chdir(assets_path)
        f = File.new(assets_path.join(manifest_filename),"w")
        f.write("{\"assets\":{\"#{nondigest_filename}\": \"#{digest_filename}\"}}")
        f.close
      
        File.new(assets_path.join(digest_filename),"w").close
        File.new(assets_path.join("#{digest_filename}.gz"),"w").close
        File.new(assets_path.join(digest_bad_filename),"w").close

        AssetsPrecompile.new(assets_path: assets_path,
          symlink_non_digested_assets_regex: Regexp.new('.*\.js$'))
          .symlink_non_digested_assets
      
        # testing for alfa.js symlink
        expect(assets_path.join(digest_filename).exist?).to be true
        expect(assets_path.join(nondigest_filename).lstat.symlink?).to be true
        expect(File.identical?( assets_path.join(nondigest_filename),
                                assets_path.join(digest_filename))).to be true
        
        # testing for alfa.js.gz symlink
        expect(assets_path.join("#{digest_filename}.gz").exist?).to be true
        expect(assets_path.join("#{nondigest_filename}.gz").lstat.symlink?).to be true
        expect(File.identical?( assets_path.join("#{nondigest_filename}.gz"),
                                assets_path.join("#{digest_filename}.gz"))).to be true
    
        # testing for NO symlink for alfa.jsx
        expect(assets_path.join(nondigest_bad_filename).exist?).to be false
      end
    end

    describe "delete_broken_symlinks" do
      it "deletes a broken symlink" do
        filename = File.basename(Tempfile.new("tempfile",assets_path))
        digest_filename = "#{filename}_digest"

        a = AssetsPrecompile.new(assets_path: assets_path)
        a.symlink_file(filename,digest_filename)
        File.unlink(assets_path.join(filename))
        a.delete_broken_symlinks
        
        expect(assets_path.join(filename).exist?).to be false
        expect(assets_path.join(digest_filename).exist?).to be false
      end
    end

    describe "clobber" do
      it "deletes files in ReactOnRails.configuration.generated_assets_dir" do

#### Problems here because in clobber dir = Rails.root.join(@generated_assets_dir)
#### which is not tmpdir, meaning we need to update real fs?

#        file = Tempfile.new("tempfile",assets_path)
#        expect(File.exist?(file)).to be true
#        AssetsPrecompile.new(generated_assets_dir: assets_path)
#          .clobber
#        expect(File.exist?(file)).to be false
      end
    end
  end
end
