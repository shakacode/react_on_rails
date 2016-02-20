require 'test_helper'
require 'tins/xt'

module Tins
  class AttemptTest < Test::Unit::TestCase

    def test_attempt_block_condition
      assert attempt(:attempts => 1, :exception_class => nil) { |c| c == 1 }
      assert attempt(:attempts => 3, :exception_class => nil) { |c| c == 1 }
      assert_equal false, attempt(:attempts => 3, :exception_class => nil) { |c| c == 4 }
      assert_nil attempt(:attempts => 0, :exception_class => nil) { |c| c == 4 }
      assert_raise(Exception) { attempt(:attempts => 3, :exception_class => nil) { raise Exception } }
    end

    class MyError < StandardError; end
    class MyException < Exception; end

    def test_attempt_default_exception
      assert attempt(1) { |c| c != 1 and raise MyError }
      assert attempt(3) { |c| c != 1 and raise MyError }
      assert_equal false, attempt(3) { |c| c != 4 and raise MyError }
      assert_nil attempt(0) { |c| c != 4 and raise MyError }
      assert_raise(Exception) { attempt(3) { raise Exception } }
    end

    def test_attempt_exception
      assert attempt(:attempts => 1, :exception_class => MyException) { |c| c != 1 and raise MyException }
      assert attempt(:attempts => 3, :exception_class => MyException) { |c| c != 1 and raise MyException }
      assert_nil attempt(:attempts => 0, :exception_class => MyException) { |c| c != 4 and raise MyException }
      assert_raise(Exception) { attempt(:attempts => 3, :exception_class => MyException) { raise Exception } }
    end

    def test_reraise_exception
      tries = 0
      assert_raise(MyException) do
        attempt(:attempts => 3, :exception_class => MyException, :reraise => true) do |c|
          tries = c; raise MyException
        end
      end
      assert_equal 3, tries
    end

    def test_reraise_exception_with_numeric_sleep
      tries = 0
      singleton_class.class_eval do
        define_method(:sleep_duration) do |duration, count|
          assert_equal 10, duration
          tries = count
          super 0, count # Let's not really sleep that long…
        end
      end
      assert_raise(MyException) do
        attempt(:attempts => 3, :exception_class => MyException, :reraise => true, :sleep => 10) do |c|
          raise MyException
        end
      end
      assert_equal 2, tries
    ensure
      singleton_class.class_eval do
        method_defined?(:sleep_duration) and remove_method :sleep_duration
      end
    end

    def test_reraise_exception_with_proc_sleep
      tries = 0
      singleton_class.class_eval do
        define_method(:sleep_duration) do |duration, count|
          assert_kind_of Proc, duration
          tries = count
          super duration, count
        end
      end
      assert_raise(MyException) do
        attempt(:attempts => 3, :exception_class => MyException, :reraise => true, :sleep => lambda { |x| 0 }) do |c|
          raise MyException
        end
      end
      assert_equal 2, tries
    ensure
      singleton_class.class_eval do
        method_defined?(:sleep_duration) and remove_method :sleep_duration
      end
    end
  end
end
