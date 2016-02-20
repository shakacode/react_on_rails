require 'spec_helper'

describe Capybara::Screenshot::RSpec::BaseReporter do
  describe '#enhance_with_screenshot' do
    it 'makes the original method available under an alias and replaces it with the enhanced method' do
      reporter_module = Module.new do
        extend Capybara::Screenshot::RSpec::BaseReporter
        enhance_with_screenshot :foo
        def foo_with_screenshot
          [foo_without_screenshot, :enhanced]
        end
      end

      klass = Class.new do
        def foo
          :original
        end
      end

      expect(klass.new.foo).to eql(:original)
      klass.send :include, reporter_module
      expect(klass.new.foo).to eql([:original, :enhanced])
    end
  end
end
