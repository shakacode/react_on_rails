require 'spec_helper'

describe Capybara::Screenshot::RSpec do
  describe '.after_failed_example' do
    context 'for a failed example in a feature that can be snapshotted' do
      before do
        allow(Capybara.page).to receive(:current_url).and_return("http://test.local")
        allow(Capybara::Screenshot::Saver).to receive(:new).and_return(mock_saver)
      end
      let(:example_group) { Module.new.send(:include, Capybara::DSL) }
      let(:example) { double("example", exception: Exception.new, example_group: example_group, metadata: {}) }
      let(:mock_saver) do
        Capybara::Screenshot::Saver.new(Capybara, Capybara.page).tap do |saver|
          allow(saver).to receive(:save)
        end
      end

      it 'instantiates a saver and calls `save` on it' do
        expect(mock_saver).to receive(:save)
        described_class.after_failed_example(example)
      end

      it 'extends the metadata with an empty hash for screenshot metadata' do
        described_class.after_failed_example(example)
        expect(example.metadata).to have_key(:screenshot)
        expect(example.metadata[:screenshot]).to eql({})
      end

      context 'when a html file gets saved' do
        before { allow(mock_saver).to receive(:html_saved?).and_return(true) }

        it 'adds the html file path to the screenshot metadata' do
          described_class.after_failed_example(example)
          expect(example.metadata[:screenshot][:html]).to match("./screenshot")
        end
      end

      context 'when an image gets saved' do
        before { allow(mock_saver).to receive(:screenshot_saved?).and_return(true) }

        it 'adds the image path to the screenshot metadata' do
          described_class.after_failed_example(example)
          expect(example.metadata[:screenshot][:image]).to match("./screenshot")
        end
      end
    end
  end
end
