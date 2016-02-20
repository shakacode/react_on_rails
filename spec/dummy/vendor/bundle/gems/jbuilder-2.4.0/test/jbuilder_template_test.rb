require "test_helper"
require "mocha/setup"
require "active_model"
require "action_view"
require "action_view/testing/resolvers"
require "active_support/cache"
require "jbuilder/jbuilder_template"

BLOG_POST_PARTIAL = <<-JBUILDER
  json.extract! blog_post, :id, :body
  json.author do
    first_name, last_name = blog_post.author_name.split(nil, 2)
    json.first_name first_name
    json.last_name last_name
  end
JBUILDER

COLLECTION_PARTIAL = <<-JBUILDER
  json.extract! collection, :id, :name
JBUILDER

RACER_PARTIAL = <<-JBUILDER
  json.extract! racer, :id, :name
JBUILDER

class Racer
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  def initialize(id, name)
    @id, @name = id, name
  end

  attr_reader :id, :name
end


BlogPost = Struct.new(:id, :body, :author_name)
Collection = Struct.new(:id, :name)
blog_authors = [ "David Heinemeier Hansson", "Pavel Pravosud" ].cycle
BLOG_POST_COLLECTION = Array.new(10){ |i| BlogPost.new(i+1, "post body #{i+1}", blog_authors.next) }
COLLECTION_COLLECTION = Array.new(5){ |i| Collection.new(i+1, "collection #{i+1}") }

ActionView::Template.register_template_handler :jbuilder, JbuilderHandler

PARTIALS = {
  "_partial.json.jbuilder"  => "foo ||= 'hello'; json.content foo",
  "_blog_post.json.jbuilder" => BLOG_POST_PARTIAL,
  "racers/_racer.json.jbuilder" => RACER_PARTIAL,
  "_collection.json.jbuilder" => COLLECTION_PARTIAL
}

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

class JbuilderTemplateTest < ActionView::TestCase
  setup do
    @context = self
    Rails.cache.clear
  end

  def jbuild(source)
    @rendered = []
    partials = PARTIALS.clone
    partials["test.json.jbuilder"] = source
    resolver = ActionView::FixtureResolver.new(partials)
    lookup_context.view_paths = [resolver]
    template = ActionView::Template.new(source, "test", JbuilderHandler, virtual_path: "test")
    json = template.render(self, {}).strip
    MultiJson.load(json)
  end

  def undef_context_methods(*names)
    self.class_eval do
      names.each do |name|
        undef_method name.to_sym if method_defined?(name.to_sym)
      end
    end
  end

  def assert_collection_rendered(result, context = nil)
    result = result.fetch(context) if context

    assert_equal 10, result.length
    assert_equal Array, result.class
    assert_equal "post body 5",        result[4]["body"]
    assert_equal "Heinemeier Hansson", result[2]["author"]["last_name"]
    assert_equal "Pavel",              result[5]["author"]["first_name"]
  end

  test "rendering" do
    result = jbuild(<<-JBUILDER)
      json.content "hello"
    JBUILDER

    assert_equal "hello", result["content"]
  end

  test "key_format! with parameter" do
    result = jbuild(<<-JBUILDER)
      json.key_format! camelize: [:lower]
      json.camel_style "for JS"
    JBUILDER

    assert_equal ["camelStyle"], result.keys
  end

  test "key_format! propagates to child elements" do
    result = jbuild(<<-JBUILDER)
      json.key_format! :upcase
      json.level1 "one"
      json.level2 do
        json.value "two"
      end
    JBUILDER

    assert_equal "one", result["LEVEL1"]
    assert_equal "two", result["LEVEL2"]["VALUE"]
  end

  test "partial! renders partial" do
    result = jbuild(<<-JBUILDER)
      json.partial! "partial"
    JBUILDER

    assert_equal "hello", result["content"]
  end

  test "partial! + locals via :locals option" do
    result = jbuild(<<-JBUILDER)
      json.partial! "partial", locals: { foo: "howdy" }
    JBUILDER

    assert_equal "howdy", result["content"]
  end

  test "partial! + locals without :locals key" do
    result = jbuild(<<-JBUILDER)
      json.partial! "partial", foo: "goodbye"
    JBUILDER

    assert_equal "goodbye", result["content"]
  end

  test "partial! renders collections" do
    result = jbuild(<<-JBUILDER)
      json.partial! "blog_post", collection: BLOG_POST_COLLECTION, as: :blog_post
    JBUILDER

    assert_collection_rendered result
  end

  test "partial! renders collections when as argument is a string" do
    result = jbuild(<<-JBUILDER)
      json.partial! "blog_post", collection: BLOG_POST_COLLECTION, as: "blog_post"
    JBUILDER

    assert_collection_rendered result
  end

  test "partial! renders collections as collections" do
    result = jbuild(<<-JBUILDER)
      json.partial! "collection", collection: COLLECTION_COLLECTION, as: :collection
    JBUILDER

    assert_equal 5, result.length
  end

  test "partial! renders as empty array for nil-collection" do
    result = jbuild(<<-JBUILDER)
      json.partial! "blog_post", collection: nil, as: :blog_post
    JBUILDER

    assert_equal [], result
  end

  test "partial! renders collection (alt. syntax)" do
    result = jbuild(<<-JBUILDER)
      json.partial! partial: "blog_post", collection: BLOG_POST_COLLECTION, as: :blog_post
    JBUILDER

    assert_collection_rendered result
  end

  test "partial! renders as empty array for nil-collection (alt. syntax)" do
    result = jbuild(<<-JBUILDER)
      json.partial! partial: "blog_post", collection: nil, as: :blog_post
    JBUILDER

    assert_equal [], result
  end

  test "render array of partials" do
    result = jbuild(<<-JBUILDER)
      json.array! BLOG_POST_COLLECTION, partial: "blog_post", as: :blog_post
    JBUILDER

    assert_collection_rendered result
  end

  test "render array of partials as empty array with nil-collection" do
    result = jbuild(<<-JBUILDER)
      json.array! nil, partial: "blog_post", as: :blog_post
    JBUILDER

    assert_equal [], result
  end

  test "render array of partials as a value" do
    result = jbuild(<<-JBUILDER)
      json.posts BLOG_POST_COLLECTION, partial: "blog_post", as: :blog_post
    JBUILDER

    assert_collection_rendered result, "posts"
  end

  test "render as empty array if partials as a nil value" do
    result = jbuild <<-JBUILDER
      json.posts nil, partial: "blog_post", as: :blog_post
    JBUILDER

    assert_equal [], result["posts"]
  end

  test "cache an empty block" do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name

    jbuild <<-JBUILDER
      json.cache! "nothing" do
      end
    JBUILDER

    result = nil

    assert_nothing_raised do
      result = jbuild(<<-JBUILDER)
        json.foo "bar"
        json.cache! "nothing" do
        end
      JBUILDER
    end

    assert_equal "bar", result["foo"]
  end

  test "fragment caching a JSON object" do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name

    jbuild <<-JBUILDER
      json.cache! "cachekey" do
        json.name "Cache"
      end
    JBUILDER

    result = jbuild(<<-JBUILDER)
      json.cache! "cachekey" do
        json.name "Miss"
      end
    JBUILDER

    assert_equal "Cache", result["name"]
  end

  test "conditionally fragment caching a JSON object" do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name

    jbuild <<-JBUILDER
      json.cache_if! true, "cachekey" do
        json.test1 "Cache"
      end
      json.cache_if! false, "cachekey" do
        json.test2 "Cache"
      end
    JBUILDER

    result = jbuild(<<-JBUILDER)
      json.cache_if! true, "cachekey" do
        json.test1 "Miss"
      end
      json.cache_if! false, "cachekey" do
        json.test2 "Miss"
      end
    JBUILDER

    assert_equal "Cache", result["test1"]
    assert_equal "Miss", result["test2"]
  end

  test "fragment caching deserializes an array" do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name

    jbuild <<-JBUILDER
      json.cache! "cachekey" do
        json.array! %w[a b c]
      end
    JBUILDER

    result = jbuild(<<-JBUILDER)
      json.cache! "cachekey" do
        json.array! %w[1 2 3]
      end
    JBUILDER

    assert_equal %w[a b c], result
  end

  test "fragment caching works with previous version of cache digests" do
    undef_context_methods :cache_fragment_name

    @context.expects :fragment_name_with_digest

    jbuild <<-JBUILDER
      json.cache! "cachekey" do
        json.name "Cache"
      end
    JBUILDER
  end

  test "fragment caching works with current cache digests" do
    undef_context_methods :fragment_name_with_digest

    @context.expects :cache_fragment_name
    ActiveSupport::Cache.expects :expand_cache_key

    jbuild <<-JBUILDER
      json.cache! "cachekey" do
        json.name "Cache"
      end
    JBUILDER
  end

  test "current cache digest option accepts options" do
    undef_context_methods :fragment_name_with_digest

    @context.expects(:cache_fragment_name).with("cachekey", skip_digest: true)
    ActiveSupport::Cache.expects :expand_cache_key

    jbuild <<-JBUILDER
      json.cache! "cachekey", skip_digest: true do
        json.name "Cache"
      end
    JBUILDER
  end

  test "does not perform caching when controller.perform_caching is false" do
    controller.perform_caching = false

    jbuild <<-JBUILDER
      json.cache! "cachekey" do
        json.name "Cache"
      end
    JBUILDER

    assert_equal Rails.cache.inspect[/entries=(\d+)/, 1], "0"
  end

  test "invokes templates via params via set!" do
    @post = BLOG_POST_COLLECTION.first

    result = jbuild(<<-JBUILDER)
      json.post @post, partial: "blog_post", as: :blog_post
    JBUILDER

    assert_equal 1, result["post"]["id"]
    assert_equal "post body 1", result["post"]["body"]
    assert_equal "David", result["post"]["author"]["first_name"]
  end

  test "invokes templates implicitly for ActiveModel objects" do
    @racer = Racer.new(123, "Chris Harris")

    result = jbuild(<<-JBUILDER)
      json.partial! @racer
    JBUILDER

    assert_equal %w[id name], result.keys
    assert_equal 123, result["id"]
    assert_equal "Chris Harris", result["name"]
  end
end
