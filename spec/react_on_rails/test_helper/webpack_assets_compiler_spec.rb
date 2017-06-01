# frozen_string_literal: true

require_relative "../spec_helper"

describe ReactOnRails::TestHelper::WebpackAssetsCompiler do
  describe "#ensureAssetsCompiled" do
    context "when assets compiler command is invalid" do
      before { allow(ReactOnRails.configuration).to receive(:npm_build_test_command).and_return("invalid command") }

      it "exits" do
        expect do
          ReactOnRails::TestHelper::WebpackAssetsCompiler.new.compile_assets
        end.to raise_error(SystemExit)
      end
    end
  end
end
