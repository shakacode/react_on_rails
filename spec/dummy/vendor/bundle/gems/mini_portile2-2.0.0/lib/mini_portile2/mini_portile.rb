require 'rbconfig'
require 'net/http'
require 'net/https'
require 'net/ftp'
require 'fileutils'
require 'tempfile'
require 'digest/md5'
require 'open-uri'
require 'cgi'
require 'rbconfig'
require 'shellwords'

# Monkey patch for Net::HTTP by ruby open-uri fix:
# https://github.com/ruby/ruby/commit/58835a9
class Net::HTTP
  private
  remove_method(:edit_path)
  def edit_path(path)
    if proxy?
      if path.start_with?("ftp://") || use_ssl?
        path
      else
        "http://#{addr_port}#{path}"
      end
    else
      path
    end
  end
end

class MiniPortile
  attr_reader :name, :version, :original_host
  attr_writer :configure_options
  attr_accessor :host, :files, :patch_files, :target, :logger

  def initialize(name, version)
    @name = name
    @version = version
    @target = 'ports'
    @files = []
    @patch_files = []
    @log_files = {}
    @logger = STDOUT

    @original_host = @host = detect_host
  end

  def download
    files_hashs.each do |file|
      download_file(file[:url], file[:local_path])
      verify_file(file)
    end
  end

  def extract
    files_hashs.each do |file|
      extract_file(file[:local_path], tmp_path)
    end
  end

  def apply_patch(patch_file)
    (
      # Not a class variable because closures will capture self.
      @apply_patch ||=
      case
      when which('git')
        lambda { |file|
          message "Running git apply with #{file}... "
          # By --work-tree=. git-apply uses the current directory as
          # the project root and will not search upwards for .git.
          execute('patch', ["git", "--work-tree=.", "apply", file], :initial_message => false)
        }
      when which('patch')
        lambda { |file|
          message "Running patch with #{file}... "
          execute('patch', ["patch", "-p1", "-i", file], :initial_message => false)
        }
      else
        raise "Failed to complete patch task; patch(1) or git(1) is required."
      end
    ).call(patch_file)
  end

  def patch
    @patch_files.each do |full_path|
      next unless File.exist?(full_path)
      apply_patch(full_path)
    end
  end

  def configure_options
    @configure_options ||= configure_defaults
  end

  def configure
    return if configured?

    md5_file = File.join(tmp_path, 'configure.md5')
    digest   = Digest::MD5.hexdigest(computed_options.to_s)
    File.open(md5_file, "w") { |f| f.write digest }

    if RUBY_PLATFORM=~/mingw|mswin/
      # Windows doesn't recognize the shebang.
      execute('configure', %w(sh ./configure) + computed_options)
    else
      execute('configure', %w(./configure) + computed_options)
    end
  end

  def compile
    execute('compile', make_cmd)
  end

  def install
    return if installed?
    execute('install', %Q(#{make_cmd} install))
  end

  def downloaded?
    missing = files_hashs.detect do |file|
      !File.exist?(file[:local_path])
    end

    missing ? false : true
  end

  def configured?
    configure = File.join(work_path, 'configure')
    makefile  = File.join(work_path, 'Makefile')
    md5_file  = File.join(tmp_path, 'configure.md5')

    stored_md5  = File.exist?(md5_file) ? File.read(md5_file) : ""
    current_md5 = Digest::MD5.hexdigest(computed_options.to_s)

    (current_md5 == stored_md5) && newer?(makefile, configure)
  end

  def installed?
    makefile  = File.join(work_path, 'Makefile')
    target_dir = Dir.glob("#{port_path}/*").find { |d| File.directory?(d) }

    newer?(target_dir, makefile)
  end

  def cook
    download unless downloaded?
    extract
    patch
    configure unless configured?
    compile
    install unless installed?

    return true
  end

  def activate
    lib_path = File.join(port_path, "lib")
    vars = {
      'PATH'          => File.join(port_path, 'bin'),
      'CPATH'         => File.join(port_path, 'include'),
      'LIBRARY_PATH'  => lib_path
    }.reject { |env, path| !File.directory?(path) }

    output "Activating #{@name} #{@version} (from #{port_path})..."
    vars.each do |var, path|
      full_path = File.expand_path(path)

      # turn into a valid Windows path (if required)
      full_path.gsub!(File::SEPARATOR, File::ALT_SEPARATOR) if File::ALT_SEPARATOR

      # save current variable value
      old_value = ENV[var] || ''

      unless old_value.include?(full_path)
        ENV[var] = "#{full_path}#{File::PATH_SEPARATOR}#{old_value}"
      end
    end

    # rely on LDFLAGS when cross-compiling
    if File.exist?(lib_path) && (@host != @original_host)
      full_path = File.expand_path(lib_path)

      old_value = ENV.fetch("LDFLAGS", "")

      unless old_value.include?(full_path)
        ENV["LDFLAGS"] = "-L#{full_path} #{old_value}".strip
      end
    end
  end

  def path
    File.expand_path(port_path)
  end

private

  def tmp_path
    "tmp/#{@host}/ports/#{@name}/#{@version}"
  end

  def port_path
    "#{@target}/#{@host}/#{@name}/#{@version}"
  end

  def archives_path
    "#{@target}/archives"
  end

  def work_path
    Dir.glob("#{tmp_path}/*").find { |d| File.directory?(d) }
  end

  def configure_defaults
    [
      "--host=#{@host}",    # build for specific target (host)
      "--enable-static",    # build static library
      "--disable-shared"    # disable generation of shared object
    ]
  end

  def configure_prefix
    "--prefix=#{File.expand_path(port_path)}"
  end

  def computed_options
    [
      configure_options,     # customized or default options
      configure_prefix,      # installation target
    ].flatten
  end

  def files_hashs
    @files.map do |file|
      hash = case file
      when String
        { :url => file }
      when Hash
        file.dup
      else
        raise ArgumentError, "files must be an Array of Stings or Hashs"
      end

      url = hash.fetch(:url){ raise ArgumentError, "no url given" }
      filename = File.basename(url)
      hash[:local_path] = File.join(archives_path, filename)
      hash
    end
  end

  def verify_file(file)
    digest = case
      when exp=file[:sha256] then Digest::SHA256
      when exp=file[:sha1] then Digest::SHA1
      when exp=file[:md5] then Digest::MD5
    end
    if digest
      is = digest.file(file[:local_path]).hexdigest
      unless is == exp.downcase
        raise "Downloaded file '#{file[:local_path]}' has wrong hash: expected: #{exp} is: #{is}"
      end
    end
  end

  def log_file(action)
    @log_files[action] ||=
      File.expand_path("#{action}.log", tmp_path).tap { |file|
        File.unlink(file) if File.exist?(file)
      }
  end

  def tar_exe
    @@tar_exe ||= begin
      %w[gtar bsdtar tar basic-bsdtar].find { |c|
        which(c)
      }
    end
  end

  def tar_compression_switch(filename)
    case File.extname(filename)
      when '.gz', '.tgz'
        'z'
      when '.bz2', '.tbz2'
        'j'
      when '.Z'
        'Z'
      else
        ''
    end
  end

  # From: http://stackoverflow.com/a/5471032/7672
  # Thanks, Mislav!
  #
  # Cross-platform way of finding an executable in the $PATH.
  #
  #   which('ruby') #=> /usr/bin/ruby
  def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable? exe
      }
    end
    return nil
  end

  def detect_host
    return @detect_host if defined?(@detect_host)

    begin
      ENV["LC_ALL"], old_lc_all = "C", ENV["LC_ALL"]

      output = `#{gcc_cmd} -v 2>&1`
      if m = output.match(/^Target\: (.*)$/)
        @detect_host = m[1]
      end

      @detect_host
    ensure
      ENV["LC_ALL"] = old_lc_all
    end
  end

  def extract_file(file, target)
    filename = File.basename(file)
    FileUtils.mkdir_p target

    message "Extracting #{filename} into #{target}... "
    execute('extract', [tar_exe, "#{tar_compression_switch(filename)}xf", file, "-C", target], {:cd => Dir.pwd, :initial_message => false})
  end

  def execute(action, command, options={})
    log_out    = log_file(action)

    Dir.chdir (options.fetch(:cd){ work_path }) do
      if options.fetch(:initial_message){ true }
        message "Running '#{action}' for #{@name} #{@version}... "
      end

      if Process.respond_to?(:spawn) && ! RbConfig.respond_to?(:java)
        args = [command].flatten + [{[:out, :err]=>[log_out, "a"]}]
        pid = spawn(*args)
        Process.wait(pid)
      else
        redirected = if command.kind_of?(Array)
                       %Q{#{command.map(&:shellescape).join(" ")} > #{log_out.shellescape} 2>&1}
                     else
                       %Q{#{command} > #{log_out.shellescape} 2>&1}
                     end
        system redirected
      end

      if $?.success?
        output "OK"
        return true
      else
        if File.exist? log_out
          output "ERROR, review '#{log_out}' to see what happened. Last lines are:"
          output("=" * 72)
          log_lines = File.readlines(log_out)
          output(log_lines[-[log_lines.length, 20].min .. -1])
          output("=" * 72)
        end
        raise "Failed to complete #{action} task"
      end
    end
  end

  def newer?(target, checkpoint)
    if (target && File.exist?(target)) && (checkpoint && File.exist?(checkpoint))
      File.mtime(target) > File.mtime(checkpoint)
    else
      false
    end
  end

  # print out a message with the logger
  def message(text)
    @logger.print text
    @logger.flush
  end

  # print out a message using the logger but return to a new line
  def output(text = "")
    @logger.puts text
    @logger.flush
  end

  # Slighly modified from RubyInstaller uri_ext, Rubinius configure
  # and adaptations of Wayne's RailsInstaller
  def download_file(url, full_path, count = 3)
    return if File.exist?(full_path)
    uri = URI.parse(url)
    begin
      case uri.scheme.downcase
      when /ftp/
        download_file_ftp(uri, full_path)
      when /http|https/
        download_file_http(url, full_path, count)
      end
    rescue Exception => e
      File.unlink full_path if File.exist?(full_path)
      output "ERROR: #{e.message}"
      raise "Failed to complete download task"
    end
  end

  def download_file_http(url, full_path, count = 3)
    filename = File.basename(full_path)
    with_tempfile(filename, full_path) do |temp_file|
      progress = 0
      total = 0
      params = {
        "Accept-Encoding" => 'identity',
        :content_length_proc => lambda{|length| total = length },
        :progress_proc => lambda{|bytes|
          new_progress = (bytes * 100) / total
          message "\rDownloading %s (%3d%%) " % [filename, new_progress]
          progress = new_progress
        }
      }
      proxy_uri = URI.parse(url).scheme.downcase == 'https' ?
                  ENV["https_proxy"] :
                  ENV["http_proxy"]
      if proxy_uri
        _, userinfo, _p_host, _p_port = URI.split(proxy_uri)
        if userinfo
          proxy_user, proxy_pass = userinfo.split(/:/).map{|s| CGI.unescape(s) }
          params[:proxy_http_basic_authentication] =
            [proxy_uri, proxy_user, proxy_pass]
        end
      end
      begin
        OpenURI.open_uri(url, 'rb', params) do |io|
          temp_file << io.read
        end
        output
      rescue OpenURI::HTTPRedirect => redirect
        raise "Too many redirections for the original URL, halting." if count <= 0
        count = count - 1
        return download_file(redirect.url, full_path, count - 1)
      rescue => e
        output e.message
        return false
      end
    end
  end

  def download_file_ftp(uri, full_path)
    filename = File.basename(uri.path)
    with_tempfile(filename, full_path) do |temp_file|
      progress = 0
      total = 0
      params = {
        :content_length_proc => lambda{|length| total = length },
        :progress_proc => lambda{|bytes|
          new_progress = (bytes * 100) / total
          message "\rDownloading %s (%3d%%) " % [filename, new_progress]
          progress = new_progress
        }
      }
      if ENV["ftp_proxy"]
        _, userinfo, _p_host, _p_port = URI.split(ENV['ftp_proxy'])
        if userinfo
          proxy_user, proxy_pass = userinfo.split(/:/).map{|s| CGI.unescape(s) }
          params[:proxy_http_basic_authentication] =
            [ENV['ftp_proxy'], proxy_user, proxy_pass]
        end
      end
      OpenURI.open_uri(uri, 'rb', params) do |io|
        temp_file << io.read
      end
      output
    end
  rescue Net::FTPError
    return false
  end

  def with_tempfile(filename, full_path)
    temp_file = Tempfile.new("download-#{filename}")
    temp_file.binmode
    yield temp_file
    temp_file.close
    File.unlink full_path if File.exist?(full_path)
    FileUtils.mkdir_p File.dirname(full_path)
    FileUtils.mv temp_file.path, full_path, :force => true
  end

  def gcc_cmd
    cc = ENV["CC"] || RbConfig::CONFIG["CC"] || "gcc"
    return cc.dup
  end

  def make_cmd
    m = ENV['MAKE'] || ENV['make'] || 'make'
    return m.dup
  end
end
