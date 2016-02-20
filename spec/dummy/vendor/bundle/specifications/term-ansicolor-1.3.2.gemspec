# -*- encoding: utf-8 -*-
# stub: term-ansicolor 1.3.2 ruby lib

Gem::Specification.new do |s|
  s.name = "term-ansicolor"
  s.version = "1.3.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Florian Frank"]
  s.date = "2015-06-23"
  s.description = "This library uses ANSI escape sequences to control the attributes of terminal output"
  s.email = "flori@ping.de"
  s.executables = ["cdiff", "decolor", "colortab", "term_mandel", "term_display"]
  s.extra_rdoc_files = ["README.rdoc", "lib/term/ansicolor.rb", "lib/term/ansicolor/attribute.rb", "lib/term/ansicolor/ppm_reader.rb", "lib/term/ansicolor/rgb_color_metrics.rb", "lib/term/ansicolor/rgb_triple.rb", "lib/term/ansicolor/version.rb"]
  s.files = ["README.rdoc", "bin/cdiff", "bin/colortab", "bin/decolor", "bin/term_display", "bin/term_mandel", "lib/term/ansicolor.rb", "lib/term/ansicolor/attribute.rb", "lib/term/ansicolor/ppm_reader.rb", "lib/term/ansicolor/rgb_color_metrics.rb", "lib/term/ansicolor/rgb_triple.rb", "lib/term/ansicolor/version.rb"]
  s.homepage = "http://flori.github.com/term-ansicolor"
  s.licenses = ["GPL-2"]
  s.rdoc_options = ["--title", "Term-ansicolor - Ruby library that colors strings using ANSI escape sequences", "--main", "README.rdoc"]
  s.rubygems_version = "2.5.1"
  s.summary = "Ruby library that colors strings using ANSI escape sequences"

  s.installed_by_version = "2.5.1" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<gem_hadar>, ["~> 1.3.1"])
      s.add_development_dependency(%q<simplecov>, [">= 0"])
      s.add_development_dependency(%q<minitest_tu_shim>, [">= 0"])
      s.add_runtime_dependency(%q<tins>, ["~> 1.0"])
    else
      s.add_dependency(%q<gem_hadar>, ["~> 1.3.1"])
      s.add_dependency(%q<simplecov>, [">= 0"])
      s.add_dependency(%q<minitest_tu_shim>, [">= 0"])
      s.add_dependency(%q<tins>, ["~> 1.0"])
    end
  else
    s.add_dependency(%q<gem_hadar>, ["~> 1.3.1"])
    s.add_dependency(%q<simplecov>, [">= 0"])
    s.add_dependency(%q<minitest_tu_shim>, [">= 0"])
    s.add_dependency(%q<tins>, ["~> 1.0"])
  end
end
