# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Utils do
    describe ".truthy_presence" do
      context "With non-empty string" do
        subject { "foobar" }
        it "returns subject (same value as presence) for a non-empty string" do
          expect(Utils.truthy_presence(subject)).to eq(subject.presence)

          # Blank strings are nil for presence
          expect(Utils.truthy_presence(subject)).to eq(subject)
        end
      end

      context "With empty string" do
        subject { "" }
        it "returns \"\" for an empty string" do
          expect(Utils.truthy_presence(subject)).to eq(subject)
        end
      end

      context "With nil object" do
        subject { nil }
        it "returns nil (same value as presence)" do
          expect(Utils.truthy_presence(subject)).to eq(subject.presence)

          # Blank strings are nil for presence
          expect(Utils.truthy_presence(subject)).to eq(nil)
        end
      end

      context "With pathname pointing to empty dir (obj.empty? is true)" do
        subject(:empty_dir) { Pathname.new(Dir.mktmpdir) }
        it "returns Pathname object" do
          # Blank strings are nil for presence
          expect(Utils.truthy_presence(empty_dir)).to eq(empty_dir)
        end
      end

      context "With pathname pointing to empty file" do
        let(:empty_dir) { Pathname.new(Dir.mktmpdir) }
        subject(:empty_file) do
          File.basename(Tempfile.new("tempfile",
                                     empty_dir))
        end
        it "returns Pathname object" do
          expect(Utils.truthy_presence(empty_file)).to eq(empty_file)
        end
      end
    end

    describe ".rails_version_less_than" do
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
end
