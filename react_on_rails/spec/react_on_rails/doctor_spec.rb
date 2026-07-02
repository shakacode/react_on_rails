# frozen_string_literal: true

require "json"
require "open3"
require "tmpdir"
require_relative "spec_helper"
require "react_on_rails/doctor"

module ReactOnRails
  RSpec.describe Doctor do
    describe "RSC Rspack validation" do
      def write_rsc_rspack_project(root, rspack_core_version:)
        FileUtils.mkdir_p(File.join(root, "config"))
        File.write(File.join(root, "config/shakapacker.yml"), <<~YAML)
          default:
            assets_bundler: rspack
        YAML
        File.write(
          File.join(root, "package.json"),
          JSON.generate(
            "dependencies" => { "react-on-rails-pro" => "17.0.0" },
            "devDependencies" => { "@rspack/core" => rspack_core_version }
          )
        )
      end

      def stub_rsc_rspack_project(root)
        allow(Rails).to receive(:root).and_return(Pathname.new(root))
        allow(ReactOnRails).to receive_message_chain(:configuration, :node_modules_location).and_return("")
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)

        stub_const("ReactOnRailsPro", Module.new)
        stub_const("ReactOnRailsPro::Configuration", Class.new)
        pro_config = instance_double(ReactOnRailsPro::Configuration, enable_rsc_support: true)
        ReactOnRailsPro.define_singleton_method(:configuration) { pro_config }
      end

      it "keeps doctor fail-closed when the RSC Rspack version is undeterminable" do
        Dir.mktmpdir do |root|
          write_rsc_rspack_project(root, rspack_core_version: "^2")
          stub_rsc_rspack_project(root)
          allow(Open3).to receive(:capture3).and_raise(Errno::ENOENT)

          doctor = described_class.new
          doctor.send(:check_rsc_rspack_version)

          expect(doctor.send(:checker).messages).to include(
            a_hash_including(
              type: :error,
              content: a_string_including(
                "RSC with Rspack requires Rspack v2 or newer",
                "Detected @rspack/core: ^2"
              )
            )
          )
        end
      end
    end
  end
end
