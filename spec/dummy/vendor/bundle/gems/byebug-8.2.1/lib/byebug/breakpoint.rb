module Byebug
  #
  # Implements breakpoints
  #
  class Breakpoint
    #
    # First breakpoint, in order of creation
    #
    def self.first
      Byebug.breakpoints.first
    end

    #
    # Last breakpoint, in order of creation
    #
    def self.last
      Byebug.breakpoints.last
    end

    #
    # Adds a new breakpoint
    #
    # @param [String] file
    # @param [Fixnum] line
    # @param [String] expr
    #
    def self.add(file, line, expr = nil)
      breakpoint = Breakpoint.new(file, line, expr)
      Byebug.breakpoints << breakpoint
      breakpoint
    end

    #
    # Removes a breakpoint
    #
    # @param id [integer] breakpoint number
    #
    def self.remove(id)
      Byebug.breakpoints.reject! { |b| b.id == id }
    end

    #
    # Returns an array of line numbers in file named +filename+ where
    # breakpoints could be set. The list will contain an entry for each
    # distinct line event call so it is possible (and possibly useful) for a
    # line number appear more than once.
    #
    # @param filename [String] File name to inspect for possible breakpoints
    #
    def self.potential_lines(filename)
      name = "#{Time.new.to_i}_#{rand(2**31)}"
      lines = {}
      iseq = RubyVM::InstructionSequence.compile(File.read(filename), name)

      iseq.disasm.each_line do |line|
        res = /^\d+ (?<insn>\w+)\s+.+\(\s*(?<lineno>\d+)\)$/.match(line)
        next unless res && res[:insn] == 'trace'

        lines[res[:lineno].to_i] = true
      end

      lines.keys
    end

    #
    # Returns true if a breakpoint could be set in line number +lineno+ in file
    # name +filename.
    #
    def self.potential_line?(filename, lineno)
      potential_lines(filename).member?(lineno)
    end

    #
    # True if there's no breakpoints
    #
    def self.none?
      Byebug.breakpoints.empty?
    end

    #
    # Prints all information associated to the breakpoint
    #
    def inspect
      meths = %w(id pos source expr hit_condition hit_count hit_value enabled?)
      values = meths.map do |field|
        "#{field}: #{send(field)}"
      end.join(', ')
      "#<Byebug::Breakpoint #{values}>"
    end
  end
end
