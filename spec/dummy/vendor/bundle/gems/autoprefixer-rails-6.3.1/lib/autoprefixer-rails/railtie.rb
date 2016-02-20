require 'yaml'

begin
  module AutoprefixedRails
    class Railtie < ::Rails::Railtie
      rake_tasks do |app|
        require 'rake/autoprefixer_tasks'
        Rake::AutoprefixerTasks.new( config(app.root) ) if defined? app.assets
      end

      if config.respond_to?(:assets) and not config.assets.nil?
        config.assets.configure do |env|
          AutoprefixerRails.install(env, config(env.root))
        end
      else
        initializer :setup_autoprefixer, group: :all do |app|
          if defined? app.assets and not app.assets.nil?
            AutoprefixerRails.install(app.assets, config(app.root))
          end
        end
      end

      # Read browsers requirements from application config
      def config(root)
        file   = File.join(root, 'config/autoprefixer.yml')
        params = ::YAML.load_file(file) if File.exist?(file)
        params ||= {}
        params = params.symbolize_keys
        params
      end
    end
  end
rescue LoadError
end
