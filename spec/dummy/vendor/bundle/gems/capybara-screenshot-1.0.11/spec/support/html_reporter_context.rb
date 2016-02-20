shared_context 'html reporter' do
  def set_example(example)
    @reporter.instance_variable_set :@failed_examples, [example]
  end

  before do
    # Mocking `RSpec::Core::Formatters::HtmlFormatter`, but only implementing the things that
    # are actually used in `HtmlLinkReporter#extra_failure_content_with_screenshot`.
    @reporter_class = Class.new do
      def extra_failure_content(exception)
        "original content"
      end
    end

    @reporter = @reporter_class.new
    @reporter.singleton_class.send :include, described_class
  end

  context 'when there is no screenshot' do
    before do
      set_example double("example", metadata: {})
    end

    it 'doesnt change the original content of the reporter' do
      expect(@reporter.extra_failure_content(nil)).to eql("original content")
    end
  end
end
