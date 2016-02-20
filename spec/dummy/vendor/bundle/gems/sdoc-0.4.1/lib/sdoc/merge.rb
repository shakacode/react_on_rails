require 'optparse'
require 'pathname'
require 'fileutils'

if Gem::Specification.respond_to?(:find_by_name) ? Gem::Specification::find_by_name("json") : Gem.available?("json")
  gem "json", ">= 1.1.3"
else
  gem "json_pure", ">= 1.1.3"
end
require 'json'

require 'sdoc/templatable'

class SDoc::Merge
  include SDoc::Templatable

  FLAG_FILE = "created.rid"

  def initialize()
    @names = []
    @urls = []
    @op_dir = 'doc'
    @title = ''
    @directories = []
  end

  def merge(options)
    parse_options options

    @outputdir = Pathname.new( @op_dir )

    check_directories
    setup_output_dir
    setup_names
    copy_files
    copy_docs if @urls.empty?
    merge_search_index
    merge_tree
    generate_index_file
  end

  def parse_options(options)
    opts = OptionParser.new do |opt|
      opt.banner = "Usage: sdoc-merge [options] directories"

      opt.on("-n", "--names [NAMES]", "Names of merged repositories. Comma separated") do |v|
        @names = v.split(',').map{|name| name.strip }
      end

      opt.on("-o", "--op [DIRECTORY]", "Set the output directory") do |v|
        @op_dir = v
      end

      opt.on("-t", "--title [TITLE]", "Set the title of merged file") do |v|
        @title = v
      end

      opt.on("-u", "--urls [URLS]", "Paths to merged docs. If you",
                    "set this files and classes won't be actualy",
                    "copied to merged build") do |v|
        @urls = v.split(' ').map{|name| name.strip }
      end
    end
    opts.parse! options
    @template_dir = Pathname.new(RDoc::Options.new.template_dir_for 'merge')
    @directories = options.dup
  end

  def merge_tree
    tree = []
    @directories.each_with_index do |dir, i|
      name = @names[i]
      url = @urls.empty? ? name : @urls[i]
      filename = File.join dir, RDoc::Generator::SDoc::TREE_FILE
      data = open(filename).read.sub(/var tree =\s*/, '')
      subtree = JSON.parse(data, :max_nesting => 0)
      item = [
        name,
        url + '/' + extract_index_path(dir),
        '',
        append_path(subtree, url)
      ]
      tree << item
    end

    dst = File.join @op_dir, RDoc::Generator::SDoc::TREE_FILE
    FileUtils.mkdir_p File.dirname(dst)
    File.open(dst, "w", 0644) do |f|
      f.write('var tree = '); f.write(tree.to_json(:max_nesting => 0))
    end
  end

  def append_path subtree, path
    subtree.map do |item|
      item[1] = path + '/' + item[1] unless item[1].empty?
      item[3] = append_path item[3], path
      item
    end
  end

  def merge_search_index
    items = []
    @indexes = {}
    @directories.each_with_index do |dir, i|
      name = @names[i]
      url = @urls.empty? ? name : @urls[i]
      filename = File.join dir, RDoc::Generator::SDoc::SEARCH_INDEX_FILE
      data = open(filename).read.sub(/var search_data =\s*/, '')
      subindex = JSON.parse(data, :max_nesting => 0)
      @indexes[name] = subindex

      searchIndex = subindex["index"]["searchIndex"]
      longSearchIndex = subindex["index"]["longSearchIndex"]
      subindex["index"]["info"].each_with_index do |info, j|
        info[2] = url + '/' + info[2]
        info[6] = i
        items << {
          :info => info,
          :searchIndex => searchIndex[j],
          :longSearchIndex => name + ' ' + longSearchIndex[j]
        }
      end
    end
    items.sort! do |a, b|
      # type (class/method/file) or name or doc part or namespace
      [a[:info][5], a[:info][0], a[:info][6], a[:info][1]] <=> [b[:info][5], b[:info][0], b[:info][6], b[:info][1]]
    end

    index = {
      :searchIndex => items.map{|item| item[:searchIndex]},
      :longSearchIndex => items.map{|item| item[:longSearchIndex]},
      :info => items.map{|item| item[:info]}
    }
    search_data = {
      :index => index,
      :badges => @names
    }

    dst = File.join @op_dir, RDoc::Generator::SDoc::SEARCH_INDEX_FILE
    FileUtils.mkdir_p File.dirname(dst)
    File.open(dst, "w", 0644) do |f|
      f.write('var search_data = '); f.write(search_data.to_json(:max_nesting => 0))
    end
  end

  def extract_index_path dir
    filename = File.join dir, 'index.html'
    content = File.open(filename) { |f| f.read }
    match = content.match(/<frame\s+src="([^"]+)"\s+name="docwin"/mi)
    if match
      match[1]
    else
      ''
    end
  end

  def generate_index_file
    templatefile = @template_dir + 'index.rhtml'
    outfile      = @outputdir + 'index.html'
    url          = @urls.empty? ? @names[0] : @urls[0]
    index_path   = url + '/' + extract_index_path(@directories[0])

    render_template templatefile, binding(), outfile
  end

  def setup_names
    unless @names.size > 0
      @directories.each do |dir|
        name = File.basename dir
        name = File.basename File.dirname(dir) if name == 'doc'
        @names << name
      end
    end
  end

  def copy_docs
    @directories.each_with_index do |dir, i|
      name = @names[i]
      index_dir = File.dirname(RDoc::Generator::SDoc::TREE_FILE)
      FileUtils.mkdir_p(File.join(@op_dir, name))

      Dir.new(dir).each do |item|
        if File.directory?(File.join(dir, item)) && item != '.' && item != '..' && item != index_dir
          FileUtils.cp_r File.join(dir, item), File.join(@op_dir, name, item), :preserve => true
        end
      end
    end
  end

  def copy_files
    dir = @directories.first
    Dir.new(dir).each do |item|
      if item != '.' && item != '..' && item != RDoc::Generator::SDoc::FILE_DIR && item != RDoc::Generator::SDoc::CLASS_DIR
        FileUtils.cp_r File.join(dir, item), @op_dir, :preserve => true
      end
    end
  end

  def setup_output_dir
    if File.exists? @op_dir
      error "#{@op_dir} already exists"
    end
    FileUtils.mkdir_p @op_dir
  end

  def check_directories
    @directories.each do |dir|
      unless File.exists?(File.join(dir, FLAG_FILE)) &&
      File.exists?(File.join(dir, RDoc::Generator::SDoc::TREE_FILE)) &&
      File.exists?(File.join(dir, RDoc::Generator::SDoc::SEARCH_INDEX_FILE))
        error "#{dir} does not seem to be an sdoc directory"
      end
    end
  end

  ##
  # Report an error message and exit

  def error(msg)
    raise RDoc::Error, msg
  end

end
