RSpec::Matchers.define(:parse) do |input, opts|
  as = block = nil
  result = trace = nil

  unless self.respond_to? :failure_message # if RSpec 2.x
    class << self
      alias_method :failure_message, :failure_message_for_should
      alias_method :failure_message_when_negated, :failure_message_for_should_not
    end
  end

  match do |parser|
    begin
      result = parser.parse(input)
      block ? 
        block.call(result) : 
        (as == result || as.nil?)
    rescue Parslet::ParseFailed => ex
      trace = ex.cause.ascii_tree if opts && opts[:trace]
      false
    end
  end

  failure_message do |is|
    if block
      "expected output of parsing #{input.inspect}" <<
      " with #{is.inspect} to meet block conditions, but it didn't"
    else
      "expected " << 
        (as ? 
          "output of parsing #{input.inspect}"<<
          " with #{is.inspect} to equal #{as.inspect}, but was #{result.inspect}" : 
          "#{is.inspect} to be able to parse #{input.inspect}") << 
        (trace ? 
          "\n"+trace : 
          '')
    end
  end

  failure_message_when_negated do |is|
    if block
      "expected output of parsing #{input.inspect} with #{is.inspect} not to meet block conditions, but it did"
    else
      "expected " << 
        (as ? 
          "output of parsing #{input.inspect}"<<
          " with #{is.inspect} not to equal #{as.inspect}" :
          
          "#{is.inspect} to not parse #{input.inspect}, but it did")
    end
  end

  # NOTE: This has a nodoc tag since the rdoc parser puts this into 
  # Object, a thing I would never allow. 
  chain :as do |expected_output=nil, &block|
    as = expected_output
    block = block
  end
end
