# pry-doc.rb
# (C) John Mair (banisterfiend); MIT license

direc = File.dirname(__FILE__)

require "#{direc}/pry-doc/version"
require "yard"

module PryDoc

  def self.load_yardoc(version)
    path = "#{File.dirname(__FILE__)}/pry-doc/core_docs_#{ version }"
    YARD::Registry.load_yardoc(path)
  end

end

case RUBY_VERSION
when /\A2\.2/
  PryDoc.load_yardoc('22')
when /\A2\.1/
  PryDoc.load_yardoc('21')
when /\A2\.0/
  PryDoc.load_yardoc('20')
else
  PryDoc.load_yardoc('19')
end

class Pry

  # do not use pry-doc if rbx is active
  if !Object.const_defined?(:RUBY_ENGINE) || RUBY_ENGINE !~ /rbx/
    self.config.has_pry_doc = true
  end

  module MethodInfo

    # Convert a method object into the `Class#method` string notation.
    # @param [Method, UnboundMethod] meth
    # @return [String] The method in string receiver notation.
    # @note This mess is needed in order to support all the modern Rubies. YOU
    #   must figure out a better way to distinguish between class methods and
    #   instance methods.
    def self.receiver_notation_for(meth)
      match = meth.inspect.match(/\A#<(?:Unbound)?Method: (.+)([#\.].+)>\z/)
      owner = meth.owner.to_s.sub(/#<.+?:(.+?)>/, '\1')
      name = match[2]
      name.sub!('#', '.') if match[1] =~ /\A#<Class:/
      owner + name
    end

    # Retrives aliases of a method
    # @param [Method, UnboundMethod] meth The method object.
    # @return [Array] The aliases of a method if it exists
    #                 otherwise, return empty array
    def self.aliases(meth)
      host        = is_singleton?(meth) ? meth.receiver : meth.owner
      method_type = is_singleton?(meth) ? :method : :instance_method

      methods = Pry::Method.send(:all_from_common, host, method_type, false).
                            map { |m| m.instance_variable_get(:@method) }

      methods.select { |m| host.send(method_type,m.name) == host.send(method_type,meth.name) }.
              reject { |m| m.name == meth.name }.
              map    { |m| host.send(method_type,m.name) }
    end

    # Checks whether method is a singleton (i.e class method)
    # @param [Method, UnboundMethod] meth
    # @param [Boolean] true if singleton
    def self.is_singleton?(meth)
      receiver_notation_for(meth).include?('.')
    end

    # Check whether the file containing the method is already cached.
    # @param [Method, UnboundMethod] meth The method object.
    # @return [Boolean] Whether the method is cached.
    def self.cached?(meth)
      !!registry_lookup(meth)
    end

    def self.registry_lookup(meth)
      obj = YARD::Registry.at(receiver_notation_for(meth))
      if obj.nil?
        if !(aliases = aliases(meth)).empty?
          obj = YARD::Registry.at(receiver_notation_for(aliases.first))
        elsif meth.owner == Kernel
          # YARD thinks that some methods are on Object when
          # they're actually on Kernel; so try again on Object if Kernel fails.
          obj = YARD::Registry.at("Object##{meth.name}")
        end
      end
      obj
    end

    # Retrieve the YARD object that contains the method data.
    # @param [Method, UnboundMethod] meth The method object.
    # @return [YARD::CodeObjects::MethodObject] The YARD data for the method.
    def self.info_for(meth)
      cache(meth)
      registry_lookup(meth)
    end

    # Determine whether a method is an eval method.
    # @return [Boolean] Whether the method is an eval method.
    def self.is_eval_method?(meth)
      file, _ = meth.source_location
      if file =~ /(\(.*\))|<.*>/
        true
      else
        false
      end
    end

    # Attempts to find the c source files if method belongs to a gem
    # and use YARD to parse and cache the source files for display
    #
    # @param [Method, UnboundMethod] meth The method object.
    def self.parse_and_cache_if_gem_cext(meth)
      if gem_dir = find_gem_dir(meth)
        if c_files_found?(gem_dir)
          warn "Scanning and caching *.c files..."
          YARD.parse("#{gem_dir}/**/*.c")
        end
      end
    end

    # @param [String] root directory path of gem that method belongs to
    # @return [Boolean] true if c files exist?
    def self.c_files_found?(gem_dir)
      Dir.glob("#{gem_dir}/**/*.c").count > 0
    end

    # @return [Object] The host of the method (receiver or owner).
    def self.method_host(meth)
      is_singleton?(meth) && Module === meth.receiver ? meth.receiver : meth.owner
    end

    # FIXME: this is unnecessarily limited to ext/ and lib/ folders
    # @return [String] The root folder of a given gem directory.
    def self.gem_root(dir)
      if index = dir.rindex(/\/(?:lib|ext)(?:\/|$)/)
        dir[0..index-1]
      end
    end

    # @param [Method, UnboundMethod] meth The method object.
    # @return [String] root directory path of gem that method belongs to,
    #                  nil if could not be found
    def self.find_gem_dir(meth)
      host = method_host(meth)

      begin
        host_source_location, _ =  WrappedModule.new(host).source_location
        break if host_source_location != nil
        return unless host.name
        host = eval(host.namespace_name)
      end while host

      # we want to exclude all source_locations that aren't gems (i.e
      # stdlib)
      if host_source_location && host_source_location =~ %r{/gems/}
        gem_root(host_source_location)
      else

        # the WrappedModule approach failed, so try our backup approach
        gem_dir_from_method(meth)
      end
    end

    # Try to guess what the gem name will be based on the name of the module.
    # We try a few approaches here depending on the `guess` parameter.
    # @param [String] name The name of the module.
    # @param [Fixnum] guess The current guessing approach to use.
    # @return [String, nil] The guessed gem name, or `nil` if out of guesses.
    def self.guess_gem_name_from_module_name(name, guess)
      case guess
      when 0
        name.downcase
      when 1
        name.scan(/[A-Z][a-z]+/).map(&:downcase).join('_')
      when 2
        name.scan(/[A-Z][a-z]+/).map(&:downcase).join('_').sub("_", "-")
      when 3
        name.scan(/[A-Z][a-z]+/).map(&:downcase).join('-')
      when 4
        name
      else
        nil
      end
    end

    # Try to recover the gem directory of a gem based on a method object.
    # @param [Method, UnboundMethod] meth The method object.
    # @return [String, nil] The located gem directory.
    def self.gem_dir_from_method(meth)
      guess = 0

      host = method_host(meth)
      return unless host.name
      root_module_name = host.name.split("::").first
      while gem_name = guess_gem_name_from_module_name(root_module_name, guess)
        matches = $LOAD_PATH.grep %r{/gems/#{gem_name}} if !gem_name.empty?
        if matches && matches.any?
          return gem_root(matches.first)
        else
          guess += 1
        end
      end

      nil
    end

    # Cache the file that holds the method or return immediately if file is
    # already cached. Return if the method cannot be cached -
    # i.e is a C stdlib method.
    # @param [Method, UnboundMethod] meth The method object.
    def self.cache(meth)
      file, _ = meth.source_location

      return if is_eval_method?(meth)
      return if cached?(meth)

      if !file
        parse_and_cache_if_gem_cext(meth)
        return
      end

      log.enter_level(Logger::FATAL) do
        YARD.parse(file)
      end
    end
  end
end
