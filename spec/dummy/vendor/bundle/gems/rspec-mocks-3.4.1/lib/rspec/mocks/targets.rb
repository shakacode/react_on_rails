module RSpec
  module Mocks
    # @private
    class TargetBase
      def initialize(target)
        @target = target
      end

      def self.delegate_to(matcher_method)
        define_method(:to) do |matcher, &block|
          unless matcher_allowed?(matcher)
            raise_unsupported_matcher(:to, matcher)
          end
          define_matcher(matcher, matcher_method, &block)
        end
      end

      def self.delegate_not_to(matcher_method, options={})
        method_name = options.fetch(:from)
        define_method(method_name) do |matcher, &block|
          case matcher
          when Matchers::Receive, Matchers::HaveReceived
            define_matcher(matcher, matcher_method, &block)
          when Matchers::ReceiveMessages, Matchers::ReceiveMessageChain
            raise_negation_unsupported(method_name, matcher)
          else
            raise_unsupported_matcher(method_name, matcher)
          end
        end
      end

      def self.disallow_negation(method_name)
        define_method(method_name) do |matcher, *_args|
          raise_negation_unsupported(method_name, matcher)
        end
      end

    private

      def matcher_allowed?(matcher)
        matcher.class.name.start_with?("RSpec::Mocks::Matchers".freeze)
      end

      def define_matcher(matcher, name, &block)
        matcher.__send__(name, @target, &block)
      end

      def raise_unsupported_matcher(method_name, matcher)
        raise UnsupportedMatcherError,
              "only the `receive`, `have_received` and `receive_messages` matchers are supported " \
              "with `#{expression}(...).#{method_name}`, but you have provided: #{matcher}"
      end

      def raise_negation_unsupported(method_name, matcher)
        raise NegationUnsupportedError,
              "`#{expression}(...).#{method_name} #{matcher.name}` is not supported since it " \
              "doesn't really make sense. What would it even mean?"
      end

      def expression
        self.class::EXPRESSION
      end
    end

    # @private
    class AllowanceTarget < TargetBase
      EXPRESSION = :allow
      delegate_to :setup_allowance
      disallow_negation :not_to
      disallow_negation :to_not
    end

    # @private
    class ExpectationTarget < TargetBase
      EXPRESSION = :expect
      delegate_to :setup_expectation
      delegate_not_to :setup_negative_expectation, :from => :not_to
      delegate_not_to :setup_negative_expectation, :from => :to_not
    end

    # @private
    class AnyInstanceAllowanceTarget < TargetBase
      EXPRESSION = :allow_any_instance_of
      delegate_to :setup_any_instance_allowance
      disallow_negation :not_to
      disallow_negation :to_not
    end

    # @private
    class AnyInstanceExpectationTarget < TargetBase
      EXPRESSION = :expect_any_instance_of
      delegate_to :setup_any_instance_expectation
      delegate_not_to :setup_any_instance_negative_expectation, :from => :not_to
      delegate_not_to :setup_any_instance_negative_expectation, :from => :to_not
    end
  end
end
