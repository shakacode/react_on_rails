require 'simplecov'
require 'webmock'
require 'vcr'

require 'pry' if RUBY_VERSION > "1.8.7"

class InceptionFormatter
  def format(result)
    Coveralls::SimpleCov::Formatter.new.format(result)
  end
end

def setup_formatter
  SimpleCov.formatter = if ENV['TRAVIS'] || ENV['COVERALLS_REPO_TOKEN']
    InceptionFormatter
  else
    SimpleCov::Formatter::HTMLFormatter
  end

  # SimpleCov.start 'test_frameworks'
  SimpleCov.start do
    add_filter do |source_file|
      source_file.filename =~ /spec/ && !(source_file.filename =~ /fixture/)
    end
  end
end

setup_formatter

require 'coveralls'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.include WebMock::API
  config.expect_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.mock_with :rspec do |c|
    c.syntax = [:should, :expect]
  end
  config.after(:suite) do
    WebMock.disable!
  end
end

def stub_api_post
  body = "{\"message\":\"\",\"url\":\"\"}"
  stub_request(:post, Coveralls::API::API_BASE+"/jobs").with(
    :body => /.+/,
    :headers => {
      'Accept'=>'*/*; q=0.5, application/xml',
      'Accept-Encoding'=>'gzip, deflate',
      'Content-Length'=>/.+/,
      'Content-Type'=>/.+/,
      'User-Agent'=>'Ruby'
    }
  ).to_return(:status => 200, :body => body, :headers => {})
end

def silence
  return yield if ENV['silence'] == 'false'

  silence_stream(STDOUT) do
    yield
  end
end

module Kernel
  def silence_stream(stream)
    old_stream = stream.dup
    stream.reopen(RUBY_PLATFORM =~ /mswin/ ? 'NUL:' : '/dev/null')
    stream.sync = true
    yield
  ensure
    stream.reopen(old_stream)
  end
end
