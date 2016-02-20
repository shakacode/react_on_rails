module Tins
  module MethodDescription
    def description(style: :namespace)
      valid_styles = %i[ namespace name parameters ]
      valid_styles.include?(style) or
        raise ArgumentError, "style has to be one of #{valid_styles * ', '}"
      result = ''
      if style == :namespace
        if owner <= Module
          result << receiver.to_s << '.' # XXX Better to use owner here as well?
        else
          result << owner.name.to_s << '#'
        end
      end
      if %i[ namespace name ].include?(style)
        result << name.to_s << '('
      end
      if respond_to?(:parameters)
        generated_name = 'x0'
        result << parameters.map { |p_type, p_name|
          p_name ||= generated_name.succ!.dup
          case p_type
          when :block
            "&#{p_name}"
          when :rest
            "*#{p_name}"
          when :keyrest
            "**#{p_name}"
          when :req
            p_name
          when :opt
            "#{p_name}=?"
          when :key
            "#{p_name}:?"
          when :keyreq
            "#{p_name}:"
          else
            [ p_name, p_type ] * ':'
          end
        } * ','
      else
        result << arity.to_s
      end
      if %i[ namespace name ].include?(style)
        result << ')'
      end
      result
    end
  end
end
