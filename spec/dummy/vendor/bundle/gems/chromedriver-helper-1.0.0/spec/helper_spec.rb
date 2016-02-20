require "spec_helper"

describe Chromedriver::Helper do
  let(:helper) { Chromedriver::Helper.new }

  describe "#binary_path" do
    context "on a linux platform" do
      before { allow(helper).to receive(:platform) { "linux32" } }
      it { expect(helper.binary_path).to match(/chromedriver$/) }
    end

    context "on a windows platform" do
      before { allow(helper).to receive(:platform) { "win" } }
      it { expect(helper.binary_path).to match(/chromedriver\.exe$/) }
    end
  end
end
