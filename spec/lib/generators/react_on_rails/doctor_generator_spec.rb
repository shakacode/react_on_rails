# frozen_string_literal: true

require_relative "../../../react_on_rails/support/generator_spec_helper"

# rubocop:disable RSpec/ContextWording, RSpec/NamedSubject, RSpec/SubjectStub
describe DoctorGenerator, type: :generator do
  include GeneratorSpec::TestCase

  destination File.expand_path("../dummy-for-generators", File.dirname(__dir__))

  context "basic functionality" do
    it "has a description" do
      expect(subject.class.desc).to include("Diagnose React on Rails setup")
    end

    it "defines verbose option" do
      expect(subject.class.class_options.keys).to include(:verbose)
    end

    it "defines fix option" do
      expect(subject.class.class_options.keys).to include(:fix)
    end
  end

  context "system checking integration" do
    it "can run diagnosis without errors" do
      # Mock all system interactions to avoid actual system calls
      allow(subject).to receive(:puts)
      allow(subject).to receive(:exit)
      allow(File).to receive_messages(exist?: false, directory?: false)
      allow(subject).to receive(:`).and_return("")

      # This should not raise any errors
      expect { subject.run_diagnosis }.not_to raise_error
    end
  end
end
# rubocop:enable RSpec/ContextWording, RSpec/NamedSubject, RSpec/SubjectStub
