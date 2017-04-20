require_relative "spec_helper"

module ReactOnRails
  RSpec.describe Utils do
    describe '.rails_version_less_than' do
      subject { Utils.rails_version_less_than('4') }

      context 'with Rails 3' do
        before { allow(Rails).to receive(:version).and_return('3') }

        it { expect(subject).to eq(true) }
      end

      context 'with Rails 3.2' do
        before { allow(Rails).to receive(:version).and_return('3.2') }

        it { expect(subject).to eq(true) }
      end

      context 'with Rails 4.2' do
        before { allow(Rails).to receive(:version).and_return('4.2') }

        it { expect(subject).to eq(false) }
      end

      context 'with Rails 10.0' do
        before { allow(Rails).to receive(:version).and_return('10.0') }

        it { expect(subject).to eq(false) }
      end
    end
  end
end
