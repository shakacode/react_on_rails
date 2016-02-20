require 'byebug/helpers/eval'

module Byebug
  #
  # Reopens the +var+ command to define the +const+ subcommand
  #
  class VarCommand < Command
    #
    # Shows constants
    #
    class ConstCommand < Command
      include Helpers::EvalHelper

      self.allow_in_post_mortem = true

      def self.regexp
        /^\s* c(?:onst)? (?:\s+ (.+))? \s*$/x
      end

      def self.description
        <<-EOD
          v[ar] c[onstant]

          #{short_description}
        EOD
      end

      def self.short_description
        'Shows constants of an object.'
      end

      def execute
        obj = warning_eval(str_obj)
        unless obj.is_a?(Module)
          return errmsg(pr('variable.errors.not_module', object: str_obj))
        end

        constants = warning_eval("#{str_obj}.constants")
        puts prv(constants.sort.map { |c| [c, obj.const_get(c)] }, 'constant')
      end

      private

      def str_obj
        @str_obj ||= @match[1] || 'self.class'
      end
    end
  end
end
