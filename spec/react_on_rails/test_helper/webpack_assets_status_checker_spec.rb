require_relative File.join("..", "support", "fixtures_helper")
require_relative "../spec_helper"

describe ReactOnRails::TestHelper::WebpackAssetsStatusChecker do
  describe "#stale_generated_webpack_files" do
    let(:client_dir) { client_dir_for(fixture_dirname) }
    let(:generated_assets_dir) { compiled_js_dir_for(fixture_dirname) }
    let(:webpack_generated_files) { %w(client-bundle.js server-bundle.js) }
    let(:server_bundle_js_file) { File.realpath(File.join(generated_assets_dir, "server-bundle.js")) }
    let(:client_bundle_js_file) { File.realpath(File.join(generated_assets_dir, "client-bundle.js")) }

    let(:checker) do
      ReactOnRails::TestHelper::WebpackAssetsStatusChecker
        .new(generated_assets_dir: generated_assets_dir,
             client_dir: client_dir,
             webpack_generated_files: webpack_generated_files)
    end

    context "when compiled assets exist and are up-to-date" do
      let(:fixture_dirname) { "assets_exist" }
      before do
        touch_files_in_dir(generated_assets_dir)
      end

      xit { expect(checker.stale_generated_webpack_files).to eq([]) }
    end

    context "when compiled assets don't exist" do
      let(:fixture_dirname) { "assets_no_exist" }

      xit do
        puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"
        puts "webpack_assets_status_checker_spec.rb: #{__LINE__},  method: #{__method__}"
        puts "checker.stale_generated_webpack_files = #{checker.stale_generated_webpack_files.ai}"
        puts "#{client_bundle_js_file}, #{server_bundle_js_file}"
        puts "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ"

        expect(checker.stale_generated_webpack_files)
          .to eq([client_bundle_js_file, server_bundle_js_file])
      end
    end

    context "when only server-bundle.js exists" do
      let(:fixture_dirname) { "assets_exist_only_server_bundle" }
      before do
        touch_files_in_dir(generated_assets_dir)
      end

      xit do
        expect(checker.stale_generated_webpack_files)
          .to eq([client_bundle_js_file])
      end
    end

    context "when assets exist but are outdated" do
      let(:fixture_dirname) { "assets_outdated" }
      before { touch_files_in_dir(client_dir) }

      xit do
        expect(checker.stale_generated_webpack_files)
          .to eq([client_bundle_js_file, server_bundle_js_file])
      end
    end
  end

  def client_dir_for(fixture_dirname)
    FixturesHelper.get_file(%W(webpack_assets #{fixture_dirname} client))
  end

  def compiled_js_dir_for(fixture_dirname)
    FixturesHelper.get_file(%W(webpack_assets #{fixture_dirname} compiled_js))
  end

  # Necessary for ensuring file mtimes of fixtures are correct
  def touch_files_in_dir(dir)
    `touch #{dir}/*`
  end
end
