direc = File.dirname(__FILE__)

class C
  def message; end
end

puts
puts "Building Sample Gem with C Extensions for testing.."
system("cd #{direc}/gem_with_cext/gems/ext/ && ruby extconf.rb && make")
puts

