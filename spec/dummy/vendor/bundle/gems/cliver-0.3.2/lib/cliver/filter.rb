# encoding: utf-8

module Cliver
  # A Namespace to hold filter procs
  module Filter
    # The identity filter returns its input unchanged.
    IDENTITY = proc { |version| version }

    # Apply to a list of requirements
    # @param requirements [Array<String>]
    # @return [Array<String>]
    def requirements(requirements)
      requirements.map do |requirement|
        req_parts = requirement.split(/\b(?=\d)/, 2)
        version = req_parts.last
        version.replace apply(version)
        req_parts.join
      end
    end

    # Apply to some input
    # @param version [String]
    # @return [String]
    def apply(version)
      to_proc.call(version)
    end
  end
end
