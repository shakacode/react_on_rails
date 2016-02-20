module Libv8
  module Make
    module_function

    def make
      unless defined?(@make)
        @make = `which gmake 2> /dev/null`.chomp
        @make = `which make`.chomp unless $?.success?
      end
      @make
    end
  end
end
