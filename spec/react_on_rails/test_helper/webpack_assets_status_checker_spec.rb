require_relative File.join("..", "support", "fixtures_helper")
require_relative "../spec_helper"

describe ReactOnRails::TestHelper::WebpackAssetsStatusChecker do
  describe "#up_to_date?" do
    let(:client_dir) { client_dir_for(fixture_dirname) }
    let(:compiled_js_dir) { compiled_js_dir_for(fixture_dirname) }
    let(:server_bundle_js_file) { File.join([compiled_js_dir, "server-bundle.js"]) }
    let(:compiled_sass_dir) { compiled_js_dir_for(fixture_dirname) }
    let(:compiled_dirs) { [compiled_js_dir, compiled_sass_dir] }
    let(:checker) do
      ReactOnRails::TestHelper::WebpackAssetsStatusChecker
        .new(compiled_dirs: compiled_dirs,
             client_dir: client_dir,
             server_bundle_js_file: server_bundle_js_file)
    end

    context "when compiled assets exist and are up-to-date" do
      let(:fixture_dirname) { "assets_exist" }
      before do
        touch_files_in_dir(compiled_js_dir)
      end

      specify { expect(checker.up_to_date?).to eq(true) }
    end

    context "when compiled assets don't exist" do
      let(:fixture_dirname) { "assets_no_exist" }

      specify { expect(checker.up_to_date?).to eq(false) }
    end

    context "when only server-bundle.js exists" do
      let(:fixture_dirname) { "assets_exist_only_server_bundle" }
      before do
        touch_files_in_dir(compiled_js_dir)
      end

      specify { expect(checker.up_to_date?).to eq(false) }
    end

    context "when only server-bundle.js exists and no compiled_dirs specified" do
      let(:fixture_dirname) { "assets_exist_only_server_bundle" }
      let(:compiled_dirs) { nil }
      before do
        touch_files_in_dir(compiled_js_dir)
      end

      specify { expect(checker.up_to_date?).to eq(false) }
    end

    context "when assets exist but are outdated" do
      let(:fixture_dirname) { "assets_outdated" }
      before { touch_files_in_dir(client_dir) }

      specify { expect(checker.up_to_date?).to eq(false) }
    end
  end

  def client_dir_for(fixture_dirname)
    FixturesHelper.get_file(%W(webpack_assets #{fixture_dirname} client))
  end

  def compiled_js_dir_for(fixture_dirname)
    FixturesHelper.get_file(%W(webpack_assets #{fixture_dirname} compiled_js))
  end

  def compiled_sass_dir_for(fixture_dirname)
    FixturesHelper.get_file(%W(webpack_assets #{fixture_dirname} compiled_sass))
  end

  # Necessary for ensuring file mtimes of fixtures are correct
  def touch_files_in_dir(dir)
    `touch #{dir}/*`
  end
end
