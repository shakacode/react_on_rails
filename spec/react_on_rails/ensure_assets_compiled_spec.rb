require_relative "simplecov_helper"
require_relative "spec_helper"

class WebpackAssetsCompilerDouble
  attr_reader :times_ran

  def initialize
    @times_ran = 0
  end

  def compile
    @times_ran += 1
  end
end

module ReactOnRails
  describe EnsureAssetsCompiled do
    let(:compiler) { WebpackAssetsCompilerDouble.new }
    let(:ensurer) { EnsureAssetsCompiled.new(checker, compiler) }

    context "when assets are not up to date" do
      let(:checker) { double_webpack_assets_checker(up_to_date: false) }

      it "compiles the webpack bundles" do
        expect { ensurer.call }.to change { compiler.times_ran }.from(0).to(1)
      end
    end

    context "when assets are up to date" do
      let(:checker) { double_webpack_assets_checker(up_to_date: true) }

      it "does not compile the webpack bundles if they exist and are up to date" do
        expect { ensurer.call }.not_to change { compiler.times_ran }
      end
    end

    def double_webpack_assets_checker(args = {})
      instance_double(WebpackAssetsStatusChecker, up_to_date?: args.fetch(:up_to_date))
    end
  end
end
