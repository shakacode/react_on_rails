require File.expand_path '../../../lib/libv8/version.rb', __FILE__

module Libv8
  module Checkout
    module_function

    GYP_SVN = 'http://gyp.googlecode.com/svn'
    V8_Source = File.expand_path '../../../vendor/v8', __FILE__
    GYP_Source = File.expand_path '../../../vendor/gyp', __FILE__

    def checkout!
      # When compiling from a source gem, it's not a git repository anymore and
      # we assume the right code is already checked out.
      return unless git?(V8_Source)

      Dir.chdir(V8_Source) do
        `git fetch`
        `git checkout #{Libv8::VERSION.gsub(/\.\d+(\.rc\d+)?$/,'')} -f`
        `rm -f .applied_patches`
      end

      return unless git?(GYP_Source)

      check_git_svn!

      Dir.chdir(GYP_Source) do
        mkf = File.readlines(File.join(V8_Source, 'Makefile'))
        idx = mkf.index {|l| l =~ /#{GYP_SVN}/} + 1
        rev = /--revision (\d+)/.match(mkf[idx])[1]
        `git fetch`
        # --git-dir is needed for older versions of git and git-svn
        `git --git-dir=../../.git/modules/vendor/gyp/ svn init #{GYP_SVN} -Ttrunk`
        `git config --replace-all svn-remote.svn.fetch trunk:refs/remotes/origin/master`
        svn_rev = `git --git-dir=../../.git/modules/vendor/gyp/ svn find-rev r#{rev} | tail -n 1`.chomp
        `git checkout #{svn_rev} -f`
      end
    end

    def git?(dir)
      File.exist?(File.join(dir, '.git'))
    end

    def check_git_svn!
      # msysgit provides git svn
      return if RUBY_PLATFORM =~ /mingw/

      unless system 'git help svn 2>&1 > /dev/null'
        fail "git-svn not installed!\nPlease install git-svn."
      end
    end
  end
end
