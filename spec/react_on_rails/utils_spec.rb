require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Utils do
    subject { Utils.rails_version_less_than("4") }

    describe ".rails_version_less_than" do
      before(:each) { Utils.instance_variable_set :@rails_version_less_than, nil }

      context "with Rails 3" do
        before { allow(Rails).to receive(:version).and_return("3") }

        it { expect(subject).to eq(true) }
      end

      context "with Rails 3.2" do
        before { allow(Rails).to receive(:version).and_return("3.2") }

        it { expect(subject).to eq(true) }
      end

      context "with Rails 4" do
        before { allow(Rails).to receive(:version).and_return("4") }

        it { expect(subject).to eq(false) }
      end

      context "with Rails 4.2" do
        before { allow(Rails).to receive(:version).and_return("4.2") }

        it { expect(subject).to eq(false) }
      end

      context "with Rails 10.0" do
        before { allow(Rails).to receive(:version).and_return("10.0") }

        it { expect(subject).to eq(false) }
      end

      context "called twice" do
        before do
          allow(Rails).to receive(:version).and_return("4.2")
        end

        it "should memoize the result" do
          2.times { Utils.rails_version_less_than("4") }

          expect(Rails).to have_received(:version).once
        end
      end
    end

    describe ".rails_version_less_than_4_1_1" do
      subject { Utils.rails_version_less_than_4_1_1 }

      before(:each) { Utils.instance_variable_set :@rails_version_less_than, nil }

      context "with Rails 4.1.0" do
        before { allow(Rails).to receive(:version).and_return("4.1.0") }

        it { expect(subject).to eq(true) }
      end

      context "with Rails 4.1.1" do
        before { allow(Rails).to receive(:version).and_return("4.1.1") }

        it { expect(subject).to eq(false) }
      end
    end
  end
end
