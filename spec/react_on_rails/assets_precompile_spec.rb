require_relative "spec_helper"
require "react_on_rails/assets_precompile"

# require "tmpdir"
# require "tempfile"

module ReactOnRails
  RSpec.describe AssetsPrecompile do
    describe "symlink_file" do
      it "creates a proper symlink"
      it "creates a proper symlink if nested"
    end

    describe "symlink_non_digested_assets" do
      it "creates the necessary symlinks"
    end

    describe "delete_broken_symlinks" do
      it "deletes a broken symlink"
    end

    describe "clobber" do
      it "deletes files in ReactOnRails.configuration.generated_assets_dir"
    end
  end
end
