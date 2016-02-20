module RubyLint
  ##
  # {RubyLint::Report} is a data container for error messages, warnings,
  # informational messages and other custom defined types of messages. It
  # should be used by the various analysis classes to store information such as
  # errors for undefined variables and warnings for potentially confusing code.
  #
  # ## Levels
  #
  # Each instance can add entries for a set of predefined reporting levels. By
  # default the following levels are defined:
  #
  # * error
  # * warning
  # * info
  #
  # Unless other levels are specified when creating an instance these levels
  # are used for each new instance. Extra levels can be specified in the
  # constructor of this class.
  #
  # ## Adding Entries
  #
  # Adding entries can be done by either calling {RubyLint::Report#add}:
  #
  #     report = RubyLint::Report.new
  #
  #     report.add(
  #       :level   => :info,
  #       :message => 'informational message',
  #       :line    => 1,
  #       :column  => 2,
  #       :file    => 'file.rb'
  #     )
  #
  # When using {RubyLint::Report#add} any invalid/disabled reporting levels
  # will be silently ignored. This makes it easier for code to add entries of a
  # particular level without having to manually check if said level is enabled.
  #
  # @!attribute [r] entries
  #  @return [Array] The entries of the report.
  #
  # @!attribute [r] levels
  #  @return [Array] The enabled levels of the report.
  #
  class Report
    attr_reader :entries, :levels

    ##
    # Reporting levels that are always available.
    #
    # @return [Array]
    #
    DEFAULT_LEVELS = [:error, :warning, :info].freeze

    ##
    # @param [Array] levels The reporting levels to enable for this instance.
    #
    def initialize(levels = DEFAULT_LEVELS)
      @levels  = levels.map(&:to_sym)
      @entries = []
    end

    ##
    # Adds a new entry to the report.
    #
    # @param [Hash] attributes
    # @option attributes [Symbol] :level The level of the message.
    #
    # @see RubyLint::Report::Entry#initialize
    #
    def add(attributes)
      level = attributes[:level].to_sym

      if valid_level?(level)
        entries << Entry.new(attributes)
      end
    end

    private

    ##
    # @param [Symbol] level
    # @return [TrueClass|FalseClass]
    #
    def valid_level?(level)
      return levels.include?(level)
    end
  end # Report
end # RubyLint
