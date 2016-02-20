require 'pathname'
require 'execjs'
require 'json'

module AutoprefixerRails
  # Ruby to JS wrapper for Autoprefixer processor instance
  class Processor

    def initialize(params = { })
      @params = params || { }
    end

    # Process `css` and return result.
    #
    # Options can be:
    # * `from` with input CSS file name. Will be used in error messages.
    # * `to` with output CSS file name.
    # * `map` with true to generate new source map or with previous map.
    def process(css, opts = { })
      opts = convert_options(opts)

      apply_wrapper =
        "(function(opts) {" +
        "return eval(process.apply(this, opts));" +
        "})"

      params = params_with_browsers(opts[:from]).merge(opts)
      result = runtime.call(apply_wrapper, [css, params])

      Result.new(result['css'], result['map'], result['warnings'])
    end

    # Return, which browsers and prefixes will be used
    def info
      runtime.eval("autoprefixer(#{ js_params }).info()")
    end

    # Parse Browserslist config
    def parse_config(config)
      config.gsub(/#[^\n]*/, '')
            .split(/\n/)
            .map(&:strip)
            .reject(&:empty?)
    end

    private

    def params_with_browsers(from = nil)
      unless from
        if defined? Rails and Rails.respond_to?(:root) and Rails.root
          from = Rails.root.join('app/assets/stylesheets').to_s
        else
          from = '.'
        end
      end

      params = @params
      if not params.has_key?(:browsers) and from
        config = find_config(from)
        if config
          params = params.dup
          params[:browsers] = parse_config(config)
        end
      end

      params
    end

    # Convert params to JS string and add browsers from Browserslist config
    def js_params
      '{ ' +
        params_with_browsers.map { |k, v| "#{k}: #{v.inspect}"}.join(', ') +
      ' }'
    end

    # Convert ruby_options to jsOptions
    def convert_options(opts)
      converted = { }

      opts.each_pair do |name, value|
        if name =~ /_/
          name = name.to_s.gsub(/_\w/) { |i| i.gsub('_', '').upcase }.to_sym
        end
        value = convert_options(value) if value.is_a? Hash
        converted[name] = value
      end

      converted
    end

    # Try to find Browserslist config
    def find_config(file)
      path = Pathname(file).expand_path.dirname

      while path.parent != path
        config = path.join('browserslist')
        return config.read if config.exist? and not config.directory?
        path = path.parent
      end

      nil
    end

    # Lazy load for JS library
    def runtime
      @runtime ||= begin
        if ExecJS.eval('typeof(Array.prototype.map)') != 'function'
          raise "Current ExecJS runtime does't support ES5. " +
                "Please install node.js."
        end

        ExecJS.compile(build_js)
      end
    end

    # Cache autoprefixer.js content
    def read_js
      @@js ||= Pathname(__FILE__).join("../../../vendor/autoprefixer.js").read
    end

    # Return processor JS with some extra methods
    def build_js
      'var global = this;' + read_js + process_proxy
    end

    # Return JS code for process method proxy
    def process_proxy
      <<-JS
        var processor;
        var process = function() {
          var result = autoprefixer.process.apply(autoprefixer, arguments);
          var warns  = result.warnings().map(function (i) {
            delete i.plugin;
            return i.toString();
          });
          var map = result.map ? result.map.toString() : null;
          return { css: result.css, map: map, warnings: warns };
        };
      JS
    end
  end
end
