# frozen_string_literal: true

require_relative "../support/generator_spec_helper"

describe BaseGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", __dir__)

  describe "--pretend mode behavior" do
    let(:base_generator) { described_class.new([], { pretend: true }) }

    it "does not chmod precompile hook script in copy_base_files" do
      allow(base_generator).to receive(:copy_file)
      allow(base_generator).to receive(:template)
      allow(base_generator).to receive_messages(
        use_rsc?: false,
        destination_root: "/fake/path"
      )

      expect(File).not_to receive(:chmod)

      base_generator.copy_base_files
    end
  end
end
