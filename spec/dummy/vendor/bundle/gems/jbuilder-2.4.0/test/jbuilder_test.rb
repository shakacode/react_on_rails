require 'test_helper'
require 'active_support/inflector'
require 'jbuilder'

def jbuild(*args, &block)
  Jbuilder.new(*args, &block).attributes!
end

Comment = Struct.new(:content, :id)

class NonEnumerable
  def initialize(collection)
    @collection = collection
  end

  delegate :map, :count, to: :@collection
end

class VeryBasicWrapper < BasicObject
  def initialize(thing)
    @thing = thing
  end

  def method_missing(name, *args, &block)
    @thing.send name, *args, &block
  end
end

# This is not Struct, because structs are Enumerable
class Person
  attr_reader :name, :age

  def initialize(name, age)
    @name, @age = name, age
  end
end

class RelationMock
  include Enumerable

  def each(&block)
    [Person.new('Bob', 30), Person.new('Frank', 50)].each(&block)
  end

  def empty?
    false
  end
end


class JbuilderTest < ActiveSupport::TestCase
  setup do
    Jbuilder.send :class_variable_set, '@@key_formatter', nil
  end

  test 'single key' do
    result = jbuild do |json|
      json.content 'hello'
    end

    assert_equal 'hello', result['content']
  end

  test 'single key with false value' do
    result = jbuild do |json|
      json.content false
    end

    assert_equal false, result['content']
  end

  test 'single key with nil value' do
    result = jbuild do |json|
      json.content nil
    end

    assert result.has_key?('content')
    assert_equal nil, result['content']
  end

  test 'multiple keys' do
    result = jbuild do |json|
      json.title 'hello'
      json.content 'world'
    end

    assert_equal 'hello', result['title']
    assert_equal 'world', result['content']
  end

  test 'extracting from object' do
    person = Struct.new(:name, :age).new('David', 32)

    result = jbuild do |json|
      json.extract! person, :name, :age
    end

    assert_equal 'David', result['name']
    assert_equal 32, result['age']
  end

  test 'extracting from object using call style for 1.9' do
    person = Struct.new(:name, :age).new('David', 32)

    result = jbuild do |json|
      json.(person, :name, :age)
    end

    assert_equal 'David', result['name']
    assert_equal 32, result['age']
  end

  test 'extracting from hash' do
    person = {:name => 'Jim', :age => 34}

    result = jbuild do |json|
      json.extract! person, :name, :age
    end

    assert_equal 'Jim', result['name']
    assert_equal 34, result['age']
  end

  test 'nesting single child with block' do
    result = jbuild do |json|
      json.author do
        json.name 'David'
        json.age  32
      end
    end

    assert_equal 'David', result['author']['name']
    assert_equal 32, result['author']['age']
  end

  test 'empty block handling' do
    result = jbuild do |json|
      json.foo 'bar'
      json.author do
      end
    end

    assert_equal 'bar', result['foo']
    assert !result.key?('author')
  end

  test 'blocks are additive' do
    result = jbuild do |json|
      json.author do
        json.name 'David'
      end

      json.author do
        json.age  32
      end
    end

    assert_equal 'David', result['author']['name']
    assert_equal 32, result['author']['age']
  end

  test 'support merge! method' do
    result = jbuild do |json|
      json.merge! 'foo' => 'bar'
    end

    assert_equal 'bar', result['foo']
  end

  test 'support merge! method in a block' do
    result = jbuild do |json|
      json.author do
        json.merge! 'name' => 'Pavel'
      end
    end

    assert_equal 'Pavel', result['author']['name']
  end

  test 'blocks are additive via extract syntax' do
    person = Person.new('Pavel', 27)

    result = jbuild do |json|
      json.author person, :age
      json.author person, :name
    end

    assert_equal 'Pavel', result['author']['name']
    assert_equal 27, result['author']['age']
  end

  test 'arrays are additive' do
    result = jbuild do |json|
      json.array! %w[foo]
      json.array! %w[bar]
    end

    assert_equal %w[foo bar], result
  end

  test 'nesting multiple children with block' do
    result = jbuild do |json|
      json.comments do
        json.child! { json.content 'hello' }
        json.child! { json.content 'world' }
      end
    end

    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'nesting single child with inline extract' do
    person = Person.new('David', 32)

    result = jbuild do |json|
      json.author person, :name, :age
    end

    assert_equal 'David', result['author']['name']
    assert_equal 32,      result['author']['age']
  end

  test 'nesting multiple children from array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.comments comments, :content
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'nesting multiple children from array when child array is empty' do
    comments = []

    result = jbuild do |json|
      json.name 'Parent'
      json.comments comments, :content
    end

    assert_equal 'Parent', result['name']
    assert_equal [], result['comments']
  end

  test 'nesting multiple children from array with inline loop' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.comments comments do |comment|
        json.content comment.content
      end
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'handles nil-collections as empty arrays' do
    result = jbuild do |json|
      json.comments nil do |comment|
        json.content comment.content
      end
    end

    assert_equal [], result['comments']
  end

  test 'nesting multiple children from a non-Enumerable that responds to #map' do
    comments = NonEnumerable.new([ Comment.new('hello', 1), Comment.new('world', 2) ])

    result = jbuild do |json|
      json.comments comments, :content
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'nesting multiple chilren from a non-Enumerable that responds to #map with inline loop' do
    comments = NonEnumerable.new([ Comment.new('hello', 1), Comment.new('world', 2) ])

    result = jbuild do |json|
      json.comments comments do |comment|
        json.content comment.content
      end
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'array! casts array-like objects to array before merging' do
    wrapped_array = VeryBasicWrapper.new(%w[foo bar])

    result = jbuild do |json|
      json.array! wrapped_array
    end

    assert_equal %w[foo bar], result
  end

  test 'nesting multiple children from array with inline loop on root' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.call(comments) do |comment|
        json.content comment.content
      end
    end

    assert_equal 'hello', result.first['content']
    assert_equal 'world', result.second['content']
  end

  test 'array nested inside nested hash' do
    result = jbuild do |json|
      json.author do
        json.name 'David'
        json.age  32

        json.comments do
          json.child! { json.content 'hello' }
          json.child! { json.content 'world' }
        end
      end
    end

    assert_equal 'hello', result['author']['comments'].first['content']
    assert_equal 'world', result['author']['comments'].second['content']
  end

  test 'array nested inside array' do
    result = jbuild do |json|
      json.comments do
        json.child! do
          json.authors do
            json.child! do
              json.name 'david'
            end
          end
        end
      end
    end

    assert_equal 'david', result['comments'].first['authors'].first['name']
  end

  test 'directly set an array nested in another array' do
    data = [ { :department => 'QA', :not_in_json => 'hello', :names => ['John', 'David'] } ]

    result = jbuild do |json|
      json.array! data do |object|
        json.department object[:department]
        json.names do
          json.array! object[:names]
        end
      end
    end

    assert_equal 'David', result[0]['names'].last
    assert !result[0].key?('not_in_json')
  end

  test 'nested jbuilder objects' do
    to_nest = Jbuilder.new{ |json| json.nested_value 'Nested Test' }

    result = jbuild do |json|
      json.value 'Test'
      json.nested to_nest
    end

    expected = {'value' => 'Test', 'nested' => {'nested_value' => 'Nested Test'}}
    assert_equal expected, result
  end

  test 'nested jbuilder object via set!' do
    to_nest = Jbuilder.new{ |json| json.nested_value 'Nested Test' }

    result = jbuild do |json|
      json.value 'Test'
      json.set! :nested, to_nest
    end

    expected = {'value' => 'Test', 'nested' => {'nested_value' => 'Nested Test'}}
    assert_equal expected, result
  end

  test 'top-level array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.array! comments do |comment|
        json.content comment.content
      end
    end

    assert_equal 'hello', result.first['content']
    assert_equal 'world', result.second['content']
  end

  test 'it allows using next in array block to skip value' do
    comments = [ Comment.new('hello', 1), Comment.new('skip', 2), Comment.new('world', 3) ]
    result = jbuild do |json|
      json.array! comments do |comment|
        next if comment.id == 2
        json.content comment.content
      end
    end

    assert_equal 2, result.length
    assert_equal 'hello', result.first['content']
    assert_equal 'world', result.second['content']
  end

  test 'extract attributes directly from array' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.array! comments, :content, :id
    end

    assert_equal 'hello', result.first['content']
    assert_equal       1, result.first['id']
    assert_equal 'world', result.second['content']
    assert_equal       2, result.second['id']
  end

  test 'empty top-level array' do
    comments = []

    result = jbuild do |json|
      json.array! comments do |comment|
        json.content comment.content
      end
    end

    assert_equal [], result
  end

  test 'dynamically set a key/value' do
    result = jbuild do |json|
      json.set! :each, 'stuff'
    end

    assert_equal 'stuff', result['each']
  end

  test 'dynamically set a key/nested child with block' do
    result = jbuild do |json|
      json.set! :author do
        json.name 'David'
        json.age 32
      end
    end

    assert_equal 'David', result['author']['name']
    assert_equal 32, result['author']['age']
  end

  test 'dynamically sets a collection' do
    comments = [ Comment.new('hello', 1), Comment.new('world', 2) ]

    result = jbuild do |json|
      json.set! :comments, comments, :content
    end

    assert_equal ['content'], result['comments'].first.keys
    assert_equal 'hello', result['comments'].first['content']
    assert_equal 'world', result['comments'].second['content']
  end

  test 'query like object' do
    result = jbuild do |json|
      json.relations RelationMock.new, :name, :age
    end

    assert_equal 2, result['relations'].length
    assert_equal 'Bob', result['relations'][0]['name']
    assert_equal 50, result['relations'][1]['age']
  end

  test 'initialize via options hash' do
    jbuilder = Jbuilder.new(key_formatter: 1, ignore_nil: 2)
    assert_equal 1, jbuilder.instance_eval{ @key_formatter }
    assert_equal 2, jbuilder.instance_eval{ @ignore_nil }
  end

  test 'key_format! with parameter' do
    result = jbuild do |json|
      json.key_format! camelize: [:lower]
      json.camel_style 'for JS'
    end

    assert_equal ['camelStyle'], result.keys
  end

  test 'key_format! with parameter not as an array' do
    result = jbuild do |json|
      json.key_format! :camelize => :lower
      json.camel_style 'for JS'
    end

    assert_equal ['camelStyle'], result.keys
  end

  test 'key_format! propagates to child elements' do
    result = jbuild do |json|
      json.key_format! :upcase
      json.level1 'one'
      json.level2 do
        json.value 'two'
      end
    end

    assert_equal 'one', result['LEVEL1']
    assert_equal 'two', result['LEVEL2']['VALUE']
  end

  test 'key_format! resets after child element' do
    result = jbuild do |json|
      json.level2 do
        json.key_format! :upcase
        json.value 'two'
      end
      json.level1 'one'
    end

    assert_equal 'two', result['level2']['VALUE']
    assert_equal 'one', result['level1']
  end

  test 'key_format! with no parameter' do
    result = jbuild do |json|
      json.key_format! :upcase
      json.lower 'Value'
    end

    assert_equal ['LOWER'], result.keys
  end

  test 'key_format! with multiple steps' do
    result = jbuild do |json|
      json.key_format! :upcase, :pluralize
      json.pill 'foo'
    end

    assert_equal ['PILLs'], result.keys
  end

  test 'key_format! with lambda/proc' do
    result = jbuild do |json|
      json.key_format! ->(key){ key + ' and friends' }
      json.oats 'foo'
    end

    assert_equal ['oats and friends'], result.keys
  end

  test 'default key_format!' do
    Jbuilder.key_format camelize: :lower
    result = jbuild{ |json| json.camel_style 'for JS' }
    assert_equal ['camelStyle'], result.keys
  end

  test 'do not use default key formatter directly' do
    Jbuilder.key_format
    jbuild{ |json| json.key 'value' }
    formatter = Jbuilder.send(:class_variable_get, '@@key_formatter')
    cache = formatter.instance_variable_get('@cache')
    assert_empty cache
  end

  test 'ignore_nil! without a parameter' do
    result = jbuild do |json|
      json.ignore_nil!
      json.test nil
    end

    assert_empty result.keys
  end

  test 'ignore_nil! with parameter' do
    result = jbuild do |json|
      json.ignore_nil! true
      json.name 'Bob'
      json.dne nil
    end

    assert_equal ['name'], result.keys

    result = jbuild do |json|
      json.ignore_nil! false
      json.name 'Bob'
      json.dne nil
    end

    assert_equal ['name', 'dne'], result.keys
  end

  test 'default ignore_nil!' do
    Jbuilder.ignore_nil

    result = jbuild do |json|
      json.name 'Bob'
      json.dne nil
    end

    assert_equal ['name'], result.keys
    Jbuilder.send(:class_variable_set, '@@ignore_nil', false)
  end

  test 'nil!' do
    result = jbuild do |json|
      json.key 'value'
      json.nil!
    end

    assert_nil result
  end

  test 'null!' do
    result = jbuild do |json|
      json.key 'value'
      json.null!
    end

    assert_nil result
  end

  test 'null! in a block' do
    result = jbuild do |json|
      json.author do
        json.name 'David'
      end

      json.author do
        json.null!
      end
    end

    assert result.key?('author')
    assert_nil result['author']
  end

  test 'empty attributes respond to empty?' do
    attributes = Jbuilder.new.attributes!
    assert attributes.empty?
    assert attributes.blank?
    assert !attributes.present?
  end

  test 'throws ArrayError when trying to add a key to an array' do
    assert_raise Jbuilder::ArrayError do
      jbuild do |json|
        json.array! %w[foo bar]
        json.fizz "buzz"
      end
    end
  end

  test 'throws NullError when trying to add properties to null' do
    assert_raise Jbuilder::NullError do
      jbuild do |json|
        json.null!
        json.foo 'bar'
      end
    end
  end

  test 'throws NullError when trying to add properties to null using block syntax' do
    assert_raise Jbuilder::NullError do
      jbuild do |json|
        json.author do
          json.null!
        end

        json.author do
          json.name "Pavel"
        end
      end
    end
  end
end
