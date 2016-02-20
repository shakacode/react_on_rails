require 'bundler/setup'
Bundler::GemHelper.install_tasks
class Bundler::GemHelper
  def clean?
    sh_with_code('git diff --exit-code --ignore-submodules')[1] == 0
  end
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

require File.expand_path '../ext/libv8/make.rb', __FILE__
require File.expand_path '../ext/libv8/checkout.rb', __FILE__
include Libv8::Make
include Libv8::Checkout

desc "setup the vendored v8 source to correspond to the libv8 gem version"
task :checkout do
  sh "git submodule update --init"
  checkout!
end

desc "compile v8 via the ruby extension mechanism"
task :compile => :devkit do
  sh "ruby ext/libv8/extconf.rb"
end

desc "manually invoke the GYP compile. Useful for seeing debug output"
task :manual_compile do
  require File.expand_path '../ext/libv8/arch.rb', __FILE__
  include Libv8::Arch
  Dir.chdir(V8_Source) do
    sh %Q{#{make} -j2 #{libv8_arch}.release ARFLAGS.target=crs}
  end
end

def get_binary_gemspec(platform = RUBY_PLATFORM)
  gemspec = eval(File.read('libv8.gemspec'))
  gemspec.platform = Gem::Platform.new(platform)
  gemspec
end

begin
  binary_gem_name = File.basename get_binary_gemspec.cache_file
rescue
  binary_gem_name = ''
end

desc "build a binary gem #{binary_gem_name}"
task :binary => :compile do
  gemspec = get_binary_gemspec
  gemspec.extensions.clear
  # We don't need most things for the binary
  gemspec.files = []
  gemspec.files += ['lib/libv8.rb', 'lib/libv8/version.rb']
  gemspec.files += ['ext/libv8/arch.rb', 'ext/libv8/location.rb', 'ext/libv8/paths.rb']
  gemspec.files += ['ext/libv8/.location.yml']
  # V8
  gemspec.files += Dir['vendor/v8/include/*']
  gemspec.files += Dir['vendor/v8/out/**/*.a']
  FileUtils.chmod 'a+r', gemspec.files
  FileUtils.mkdir_p 'pkg'
  package = if Gem::VERSION < '2.0.0'
    Gem::Builder.new(gemspec).build
  else
    require 'rubygems/package'
    Gem::Package.build(gemspec)
  end
  FileUtils.mv(package, 'pkg')
end

desc "clean up artifacts of the build"
task :clean do
  sh "rm -rf pkg"
  sh "git clean -df"
  sh "cd #{V8_Source} && git checkout -f && git clean -dxf"
  if Dir.chdir GYP_Source
    sh "git checkout -f"
    puts "git clean -dxf"
    `git clean -dxf`
  end
end

task :devkit do
  begin
    if RUBY_PLATFORM =~ /mingw/
      require "devkit"
    end
  rescue LoadError => e
    abort "Failed to activate RubyInstaller's DevKit required for compilation."
  end
end

namespace :build do
  ['x86_64-linux', 'x86-linux'].each do |arch|
    desc "build binary gem for #{arch}"
    task arch do
      arch_dir = Pathname(__FILE__).dirname.join("release/#{arch}")
      Dir.chdir(arch_dir) do
        sh "vagrant up"
        sh "vagrant ssh -c 'cd /vagrant && rm -rf libv8 && git clone /libv8/.git libv8'"
        sh "vagrant ssh -c 'cd /vagrant/libv8 && bundle install --path vendor/bundle'"
        sh "vagrant ssh -c 'cd /vagrant/libv8 && bundle exec rake checkout binary'"
        sh "vagrant ssh -c 'cp /vagrant/libv8/pkg/*.gem /vagrant'"
      end
    end
  end

end

task :default => [:checkout, :compile, :spec]
task :build => [:clean, :checkout]
