require 'spec_helper'
require 'capybara-screenshot/helpers'

describe Capybara::Screenshot::RSpec::TextReporter do
  before do
    # Mocking `RSpec::Core::Formatters::ProgressFormatter`, but only implementing the methods that
    # are actually used in `TextReporter#dump_failure_info_with_screenshot`.
    @reporter_class = Class.new do
      attr_reader :output

      def initialize
        @output = StringIO.new
      end

      protected

      def long_padding
        "  "
      end

      def failure_color(str)
        "colorized(#{str})"
      end

      private

      def dump_failure_info(example)
        output.puts "original failure info"
      end
      alias_method :example_failed, :dump_failure_info
    end

    @reporter = @reporter_class.new
    @reporter.singleton_class.send :include, described_class
  end

  let(:example_failed_method) do
    if ::RSpec::Core::Version::STRING.to_i <= 2
      :dump_failure_info
    else
      :example_failed
    end
  end

  def example_failed_method_argument_double(metadata = {})
    example_group = Module.new.send(:include, Capybara::DSL)
    example = double("example", metadata: metadata, example_group: example_group)
    if ::RSpec::Core::Version::STRING.to_i <= 2
      example
    else
      double("notification").tap do |notification|
        allow(notification).to receive(:example).and_return(example)
      end
    end
  end

  context 'when there is no screenshot' do
    let(:example) { example_failed_method_argument_double }

    it 'doesnt change the original output of the reporter' do
      @reporter.send(example_failed_method, example)
      expect(@reporter.output.string).to eql("original failure info\n")
    end
  end

  context 'when a html file was saved' do
    let(:example) { example_failed_method_argument_double(screenshot: { html: "path/to/html" }) }

    it 'appends the html file path to the original output' do
      @reporter.send(example_failed_method, example)
      expect(@reporter.output.string).to eql("original failure info\n  #{CapybaraScreenshot::Helpers.yellow("HTML screenshot: file://path/to/html")}\n")
    end
  end

  context 'when a html file and an image were saved' do
    let(:example) { example_failed_method_argument_double(screenshot: { html: "path/to/html", image: "path/to/image" }) }

    it 'appends the image path to the original output' do
      @reporter.send(example_failed_method, example)
      expect(@reporter.output.string).to eql("original failure info\n  #{CapybaraScreenshot::Helpers.yellow("HTML screenshot: file://path/to/html")}\n  #{CapybaraScreenshot::Helpers.yellow("Image screenshot: file://path/to/image")}\n")
    end
  end


  it 'works with older RSpec formatters where `#red` is used instead of `#failure_color`' do
    old_reporter_class = Class.new(@reporter_class) do
      undef_method :failure_color
      def red(str)
        "red(#{str})"
      end
    end
    old_reporter = old_reporter_class.new
    old_reporter.singleton_class.send :include, described_class
    example = example_failed_method_argument_double(screenshot: { html: "path/to/html" })
    old_reporter.send(example_failed_method, example)
    expect(old_reporter.output.string).to eql("original failure info\n  #{CapybaraScreenshot::Helpers.yellow("HTML screenshot: file://path/to/html")}\n")
  end
end
