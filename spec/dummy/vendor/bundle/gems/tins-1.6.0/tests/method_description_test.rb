require 'test_helper'
require 'tins/xt'

module Tins
  class MethodDescriptionTest < Test::Unit::TestCase
    class A
      def foo
      end

      def self.foo
      end
    end

    def test_static_nonstatic
      assert_equal 'Tins::MethodDescriptionTest::A#foo()', A.instance_method(:foo).to_s
      assert_equal '#<UnboundMethod: Tins::MethodDescriptionTest::A#foo()>', A.instance_method(:foo).inspect
      assert_equal 'Tins::MethodDescriptionTest::A.foo()', A.method(:foo).to_s
      assert_equal '#<Method: Tins::MethodDescriptionTest::A.foo()>', A.method(:foo).inspect
    end

    class B
      def foo(x, y = 1, *r, &b)
      end
    end

    def test_standard_parameters_namespace
      assert_equal 'Tins::MethodDescriptionTest::B#foo(x,y=?,*r,&b)',
        B.instance_method(:foo).to_s
    end

    def test_standard_parameters_name
      assert_equal 'foo(x,y=?,*r,&b)',
        B.instance_method(:foo).description(style: :name)
    end

    def test_standard_parameters_parameters
      assert_equal 'x,y=?,*r,&b',
        B.instance_method(:foo).description(style: :parameters)
    end

    def test_a_cstyle_method_from_hash
      assert_equal "Hash#store(x1,x2)", ({}.method(:store).description)
    end

    if RUBY_VERSION >= "2.0"
      eval %{
        class C
          def foo(x, k: true, &b)
          end

          def bar(x, **k, &b)
          end
        end

        def test_keyword_parameters
          assert_equal 'Tins::MethodDescriptionTest::C#foo(x,k:?,&b)', C.instance_method(:foo).to_s
          assert_equal 'Tins::MethodDescriptionTest::C#bar(x,**k,&b)', C.instance_method(:bar).to_s
        end
      }
    end

    if RUBY_VERSION >= "2.1"
      eval %{
        class D
          def foo(x, k:, &b)
          end
        end

        def test_keyword_parameters_required
          assert_equal 'Tins::MethodDescriptionTest::D#foo(x,k:,&b)', D.instance_method(:foo).to_s
        end
      }
    end
  end
end
