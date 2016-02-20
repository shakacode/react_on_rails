require File.join(File.dirname(__FILE__), '/spec_helper')

describe RDoc::Generator::SDoc do
  before :each do
    @options = RDoc::Options.new
    @options.setup_generator 'sdoc'
    @parser = @options.option_parser
  end

  it "should find sdoc generator" do
    RDoc::RDoc::GENERATORS.must_include 'sdoc'
  end

  it "should use sdoc generator" do
    @options.generator.must_equal RDoc::Generator::SDoc
    @options.generator_name.must_equal 'sdoc'
  end

  it "should parse github option" do
    assert !@options.github

    out, err = capture_io do
      @parser.parse %w[--github]
    end

    err.wont_match /^invalid options/
    @options.github.must_equal true
  end

  it "should parse github short-hand option" do
    assert !@options.github

    out, err = capture_io do
      @parser.parse %w[-g]
    end

    err.wont_match /^invalid options/
    @options.github.must_equal true
  end

  it "should parse no search engine index option" do
    @options.search_index.must_equal true

    out, err = capture_io do
      @parser.parse %w[--without-search]
    end

    err.wont_match /^invalid options/
    @options.search_index.must_equal false
  end

  it "should parse search-index shorthand option" do
    @options.search_index.must_equal true
    out, err = capture_io do
      @parser.parse %w[-s]
    end

    err.wont_match /^invalid options/
    @options.search_index.must_equal false
  end

end
