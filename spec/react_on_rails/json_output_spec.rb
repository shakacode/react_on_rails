require_relative "spec_helper"
require "react_on_rails/json_output"

module ReactOnRails
  describe JsonOutput do
    subject{ described_class.new(hash_value.to_json) }

    let(:hash_value) do
      {
        simple: 'hello world',
        special: '<>&\u2028\u2029',
      }
    end

    let(:escaped_json) do
      '{"simple":"hello world","special":"\\u003c\\u003e\\u0026\\\\u2028\\\\u2029"}'
    end

    shared_examples :escaped_json do
      it 'returns a well-formatted json with escaped characters' do
        expect(subject.escaped).to eq(escaped_json)
      end
    end

    describe '#escaped' do
      context 'with Rails version 4 and higher' do
        before { allow(Rails).to receive(:version).and_return('4.2') }

        it_behaves_like :escaped_json
      end

      context 'with Rails version lower than 4' do
        before { allow(Rails).to receive(:version).and_return('3.2') }

        it_behaves_like :escaped_json
      end
    end

    describe '#escaped_without_erb_utils' do
      it_behaves_like :escaped_json
    end
  end
end
