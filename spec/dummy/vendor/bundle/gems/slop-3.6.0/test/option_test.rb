require 'helper'

class OptionTest < TestCase
  def option(*args, &block)
    Slop.new.on(*args, &block)
  end

  def option_with_argument(*args, &block)
    options = args.shift
    slop = Slop.new
    option = slop.opt(*args)
    slop.parse(options)
    slop.options.find {|opt| opt.key == option.key }
  end

  def option_value(*args, &block)
    option_with_argument(*args, &block).value
  end

  test "expects_argument?" do
    assert option(:f=).expects_argument?
    assert option(:foo=).expects_argument?
    assert option(:foo, :argument => true).expects_argument?
  end

  test "accepts_optional_argument?" do
    refute option(:f=).accepts_optional_argument?
    assert option(:f=, :argument => :optional).accepts_optional_argument?
    assert option(:f, :optional_argument => true).accepts_optional_argument?
  end

  test "key" do
    assert_equal 'foo', option(:foo).key
    assert_equal 'foo', option(:f, :foo).key
    assert_equal 'f', option(:f).key
  end

  test "call" do
    foo = nil
    option(:f, :callback => proc { foo = "bar" }).call
    assert_equal "bar", foo
    option(:f) { foo = "baz" }.call
    assert_equal "baz", foo
    option(:f) { |o| assert_equal 1, o }.call(1)
  end

  # type casting

  test "proc/custom type cast" do
    assert_equal 1, option_value(%w'-f 1', :f=, :as => proc {|x| x.to_i })
    assert_equal "oof", option_value(%w'-f foo', :f=, :as => proc {|x| x.reverse })
  end

  test "integer type cast" do
    opts = Slop.new
    opts.on :f=, :as => Integer
    opts.parse %w'-f 1'
    assert_equal 1, opts[:f]

    opts = Slop.new(:strict => true) { on :r=, :as => Integer }
    assert_raises(Slop::InvalidArgumentError) { opts.parse %w/-r abc/ }
  end

  test "float type cast" do
    opts = Slop.new(:strict => true) { on :r=, :as => Float }
    assert_raises(Slop::InvalidArgumentError) { opts.parse %w/-r abc/ }
  end

  test "symbol type cast" do
    assert_equal :foo, option_value(%w'-f foo', :f=, :as => Symbol)
  end

  test "range type cast" do
    assert_equal((1..10), option_value(%w/-r 1..10/, :r=, :as => Range))
    assert_equal((1..10), option_value(%w/-r 1-10/, :r=, :as => Range))
    assert_equal((1..10), option_value(%w/-r 1,10/, :r=, :as => Range))
    assert_equal((1...10), option_value(%w/-r 1...10/, :r=, :as => Range))
    assert_equal((-1..10), option_value(%w/-r -1..10/, :r=, :as => Range))
    assert_equal((1..-10), option_value(%w/-r 1..-10/, :r=, :as => Range))
    assert_equal((1..1), option_value(%w/-r 1/, :r=, :as => Range))
    assert_equal((-1..10), option_value(%w/-r -1..10/, :r, :as => Range, :optional_argument => true))

    opts = Slop.new(:strict => true) { on :r=, :as => Range }
    assert_raises(Slop::InvalidArgumentError) { opts.parse %w/-r abc/ }
  end

  test "array type cast" do
    assert_equal %w/lee john bill/, option_value(%w/-p lee,john,bill/, :p=, :as => Array)
    assert_equal %w/lee john bill jeff jill/, option_value(%w/-p lee,john,bill -p jeff,jill/, :p=, :as => Array)
    assert_equal %w/lee john bill/, option_value(%w/-p lee:john:bill/, :p=, :as => Array, :delimiter => ':')
    assert_equal %w/lee john,bill/, option_value(%w/-p lee,john,bill/, :p=, :as => Array, :limit => 2)
    assert_equal %w/lee john:bill/, option_value(%w/-p lee:john:bill/, :p=, :as => Array, :limit => 2, :delimiter => ':')
  end

  test "regexp type cast" do
    assert_equal Regexp.new("foo"), option_value(%w/-p foo/, :p=, :as => Regexp)
  end

  test "adding custom types" do
    opts = Slop.new
    opt = opts.on :f=, :as => :reverse
    opt.types[:reverse] = proc { |v| v.reverse }
    opts.parse %w'-f bar'
    assert_equal 'rab', opt.value
  end

  test "count type" do
    assert_equal 3, option_value(%w/-c -c -c/, :c, :as => :count)
    assert_equal 0, option_value(%w/-a -b -z/, :c, :as => :count)
    assert_equal 3, option_value(%w/-vvv/, :v, :as => :count)
  end

  # end type casting tests

  test "using a default value as fallback" do
    opts = Slop.new
    opts.on :f, :argument => :optional, :default => 'foo'
    opts.parse %w'-f'
    assert_equal 'foo', opts[:f]
  end

  test "printing options" do
    slop = Slop.new
    slop.opt :n, :name=, 'Your name'
    slop.opt :age=, 'Your age'
    slop.opt :V, 'Display the version'

    assert_equal "    -n, --name      Your name", slop.fetch_option(:name).to_s
    assert_equal "        --age       Your age", slop.fetch_option(:age).to_s
    assert_equal "    -V,             Display the version", slop.fetch_option(:V).help
  end

  test "printing options that have defaults" do
    opts = Slop.new
    opts.on :n, :name=, 'Your name', :default => 'Lee'

    assert_equal "    -n, --name      Your name (default: Lee)", opts.fetch_option(:name).to_s
  end

  test "overwriting the help text" do
    slop = Slop.new
    slop.on :foo, :help => '    -f, --foo  SOMETHING FOOEY'
    assert_equal '    -f, --foo  SOMETHING FOOEY', slop.fetch_option(:foo).help
  end
end
