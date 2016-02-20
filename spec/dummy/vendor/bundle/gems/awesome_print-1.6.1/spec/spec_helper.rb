# Copyright (c) 2010-2013 Michael Dvorkin
#
# Awesome Print is freely distributable under the terms of MIT license.
# See LICENSE file or http://www.opensource.org/licenses/mit-license.php
#------------------------------------------------------------------------------
#
# Running specs from the command line:
#   $ rake spec                   # Entire spec suite.
#   $ rspec spec/objects_spec.rb  # Individual spec file.
#
# NOTE: To successfully run specs with Ruby 1.8.6 the older versions of
# Bundler and RSpec gems are required:
#
# $ gem install bundler -v=1.0.2
# $ gem install rspec -v=2.6.0
#
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'awesome_print'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each do |file|
  require file
end

def stub_dotfile!
  dotfile = File.join(ENV["HOME"], ".aprc")
  expect(File).to receive(:readable?).at_least(:once).with(dotfile).and_return(false)
end

def capture!
  standard, $stdout = $stdout, StringIO.new
  yield
ensure
  $stdout = standard
end

# The following is needed for the Infinity Test. It runs tests as subprocesses,
# which sets STDOUT.tty? to false and would otherwise prematurely disallow colors.
### AwesomePrint.force_colors!

# Ruby 1.8.6 only: define missing String methods that are needed for the specs to pass.
if RUBY_VERSION < '1.8.7'
  class String
    def shellescape # Taken from Ruby 1.9.2 standard library, see lib/shellwords.rb.
      return "''" if self.empty?
      str = self.dup
      str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/n, "\\\\\\1")
      str.gsub!(/\n/, "'\n'")
      str
    end

    def start_with?(*prefixes)
      prefixes.each do |prefix|
        prefix = prefix.to_s
        return true if prefix == self[0, prefix.size]
      end
      false
    end

    def end_with?(*suffixes)
      suffixes.each do |suffix|
        suffix = suffix.to_s
        return true if suffix == self[-suffix.size, suffix.size]
      end
      false
    end
  end
end
