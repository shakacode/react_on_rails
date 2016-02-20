require 'spec_helper'

describe Capybara::Screenshot do
  describe '.register_driver' do
    before(:all) do
      @original_drivers = Capybara::Screenshot.registered_drivers.dup
    end

    after(:all) do
      Capybara::Screenshot.registered_drivers = @original_drivers
    end

    it 'stores driver with block' do
      block = lambda {}
      Capybara::Screenshot.register_driver :foo, &block

      expect(Capybara::Screenshot.registered_drivers[:foo]).to eql(block)
    end
  end

  describe '.register_filename_prefix_formatter' do
    before(:all) do
      @original_formatters = Capybara::Screenshot.filename_prefix_formatters.dup
    end

    after(:all) do
      Capybara::Screenshot.filename_prefix_formatters = @original_formatters
    end

    it 'stores test type with block' do
      block = lambda { |arg| }
      Capybara::Screenshot.register_filename_prefix_formatter :foo, &block

      expect(Capybara::Screenshot.filename_prefix_formatters[:foo]).to eql(block)
    end
  end

  describe '.filename_prefix_for' do
    it 'returns "screenshot" for undefined formatter' do
      expect(Capybara::Screenshot.filename_prefix_for(:foo, double('test'))).to eql('screenshot')
    end
  end

  describe '.append_screenshot_path' do
    it 'prints a deprecation message and delegates to RSpec.add_link_to_screenshot_for_failed_examples' do
      begin
        original_stderr = $stderr
        $stderr = StringIO.new
        expect {
          Capybara::Screenshot.append_screenshot_path = false
        }.to change {
          Capybara::Screenshot::RSpec.add_link_to_screenshot_for_failed_examples
        }.from(true).to(false)
        expect($stderr.string).to include("append_screenshot_path is deprecated")
      ensure
        $stderr = original_stderr
      end
    end
  end

  describe '#prune' do
    before do
      Capybara::Screenshot.reset_prune_history
    end

    it 'prunes once by default' do
      expect(Capybara::Screenshot::Pruner).to receive(:new).and_call_original.once
      3.times { Capybara::Screenshot.prune }
    end

    it 'prunes every time if option force: true' do
      expect(Capybara::Screenshot::Pruner).to receive(:new).and_call_original.exactly(3).times
      3.times { Capybara::Screenshot.prune(force: true) }
    end

    context 'prune strategy' do
      let(:prune_strategy) { { keep: 100 } }
      before do
        Capybara::Screenshot.prune_strategy = prune_strategy
      end

      it 'is passed to initializer' do
        expect(Capybara::Screenshot::Pruner).to receive(:new).with(prune_strategy).and_call_original
        Capybara::Screenshot.prune
      end
    end
  end
end
