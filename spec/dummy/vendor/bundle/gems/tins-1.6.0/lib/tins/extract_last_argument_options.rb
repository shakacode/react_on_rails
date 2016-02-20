module Tins
  module ExtractLastArgumentOptions
    def extract_last_argument_options
      last_argument = last
      if last_argument.respond_to?(:to_hash) and
        options = last_argument.to_hash.dup
      then
        return self[0..-2], options
      else
        return dup, {}
      end
    end
  end
end
