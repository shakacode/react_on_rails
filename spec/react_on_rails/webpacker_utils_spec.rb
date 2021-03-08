# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  describe WebpackerUtils do
    describe ".using_webapcker?" do
      subject do
        described_class.using_webpacker?
      end

      it { is_expected.to eq(true) }
    end
  end
end
