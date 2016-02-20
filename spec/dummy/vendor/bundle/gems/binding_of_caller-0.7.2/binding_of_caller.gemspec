# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "binding_of_caller"
  s.version = "0.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["John Mair (banisterfiend)"]
  s.date = "2013-06-07"
  s.description = "Retrieve the binding of a method's caller. Can also retrieve bindings even further up the stack."
  s.email = "jrmair@gmail.com"
  s.extensions = ["ext/binding_of_caller/extconf.rb"]
  s.files = [".gemtest", ".gitignore", ".travis.yml", ".yardopts", "Gemfile", "HISTORY", "LICENSE", "README.md", "Rakefile", "binding_of_caller.gemspec", "examples/example.rb", "ext/binding_of_caller/binding_of_caller.c", "ext/binding_of_caller/extconf.rb", "ext/binding_of_caller/ruby_headers/192/debug.h", "ext/binding_of_caller/ruby_headers/192/dln.h", "ext/binding_of_caller/ruby_headers/192/eval_intern.h", "ext/binding_of_caller/ruby_headers/192/id.h", "ext/binding_of_caller/ruby_headers/192/iseq.h", "ext/binding_of_caller/ruby_headers/192/method.h", "ext/binding_of_caller/ruby_headers/192/node.h", "ext/binding_of_caller/ruby_headers/192/regenc.h", "ext/binding_of_caller/ruby_headers/192/regint.h", "ext/binding_of_caller/ruby_headers/192/regparse.h", "ext/binding_of_caller/ruby_headers/192/rubys_gc.h", "ext/binding_of_caller/ruby_headers/192/thread_pthread.h", "ext/binding_of_caller/ruby_headers/192/thread_win32.h", "ext/binding_of_caller/ruby_headers/192/timev.h", "ext/binding_of_caller/ruby_headers/192/transcode_data.h", "ext/binding_of_caller/ruby_headers/192/version.h", "ext/binding_of_caller/ruby_headers/192/vm_core.h", "ext/binding_of_caller/ruby_headers/192/vm_exec.h", "ext/binding_of_caller/ruby_headers/192/vm_insnhelper.h", "ext/binding_of_caller/ruby_headers/192/vm_opts.h", "ext/binding_of_caller/ruby_headers/193/addr2line.h", "ext/binding_of_caller/ruby_headers/193/atomic.h", "ext/binding_of_caller/ruby_headers/193/constant.h", "ext/binding_of_caller/ruby_headers/193/debug.h", "ext/binding_of_caller/ruby_headers/193/dln.h", "ext/binding_of_caller/ruby_headers/193/encdb.h", "ext/binding_of_caller/ruby_headers/193/eval_intern.h", "ext/binding_of_caller/ruby_headers/193/id.h", "ext/binding_of_caller/ruby_headers/193/internal.h", "ext/binding_of_caller/ruby_headers/193/iseq.h", "ext/binding_of_caller/ruby_headers/193/method.h", "ext/binding_of_caller/ruby_headers/193/node.h", "ext/binding_of_caller/ruby_headers/193/parse.h", "ext/binding_of_caller/ruby_headers/193/regenc.h", "ext/binding_of_caller/ruby_headers/193/regint.h", "ext/binding_of_caller/ruby_headers/193/regparse.h", "ext/binding_of_caller/ruby_headers/193/revision.h", "ext/binding_of_caller/ruby_headers/193/rubys_gc.h", "ext/binding_of_caller/ruby_headers/193/thread_pthread.h", "ext/binding_of_caller/ruby_headers/193/thread_win32.h", "ext/binding_of_caller/ruby_headers/193/timev.h", "ext/binding_of_caller/ruby_headers/193/transcode_data.h", "ext/binding_of_caller/ruby_headers/193/transdb.h", "ext/binding_of_caller/ruby_headers/193/version.h", "ext/binding_of_caller/ruby_headers/193/vm_core.h", "ext/binding_of_caller/ruby_headers/193/vm_exec.h", "ext/binding_of_caller/ruby_headers/193/vm_insnhelper.h", "ext/binding_of_caller/ruby_headers/193/vm_opts.h", "lib/binding_of_caller.rb", "lib/binding_of_caller/mri2.rb", "lib/binding_of_caller/rubinius.rb", "lib/binding_of_caller/version.rb", "test/test_binding_of_caller.rb"]
  s.homepage = "http://github.com/banister/binding_of_caller"
  s.require_paths = ["lib"]
  s.rubygems_version = "2.0.3"
  s.summary = "Retrieve the binding of a method's caller. Can also retrieve bindings even further up the stack."
  s.test_files = ["test/test_binding_of_caller.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<debug_inspector>, [">= 0.0.1"])
      s.add_development_dependency(%q<bacon>, [">= 0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
    else
      s.add_dependency(%q<debug_inspector>, [">= 0.0.1"])
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<rake>, [">= 0"])
    end
  else
    s.add_dependency(%q<debug_inspector>, [">= 0.0.1"])
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<rake>, [">= 0"])
  end
end
