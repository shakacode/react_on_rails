def fake_makefile
  File.open(File.join(File.dirname(__FILE__), "Makefile"), "w") do |f|
    f.puts %[install:\n\techo "Nada."]
  end
end

def mri_2?
  defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" &&
    RUBY_VERSION =~ /^2/
end

def rbx?
  defined?(RUBY_ENGINE) && RUBY_ENGINE =~ /rbx/
end

if mri_2? || rbx?
  fake_makefile
else
  require 'mkmf'

  $CFLAGS += " -O0"
  $CFLAGS += " -std=c99"

  case RUBY_VERSION
  when /1.9.2/
    $CFLAGS += " -I./ruby_headers/192/ -DRUBY_192"
  when /1.9.3/
    $CFLAGS += " -I./ruby_headers/193/ -DRUBY_193"
  end

  create_makefile('binding_of_caller')
end

