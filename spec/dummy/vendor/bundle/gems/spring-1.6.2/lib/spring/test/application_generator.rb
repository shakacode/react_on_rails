module Spring
  module Test
    class ApplicationGenerator
      attr_reader :version_constraint, :version, :application

      def initialize(version_constraint)
        @version_constraint = version_constraint
        @version            = RailsVersion.new(version_constraint.split(' ').last)
        @application        = Application.new(root)
        @bundled            = false
      end

      def test_root
        Pathname.new Spring::Test.root
      end

      def root
        test_root.join("apps/rails-#{version.major}-#{version.minor}-spring-#{Spring::VERSION}")
      end

      def system(command)
        if ENV["SPRING_DEBUG"]
          puts "$ #{command}\n"
        else
          command = "(#{command}) > /dev/null"
        end

        Kernel.system(command) or raise "command failed: #{command}"
        puts if ENV["SPRING_DEBUG"]
      end

      def generate
        Bundler.with_clean_env { generate_files }
        install_spring
        generate_scaffold
      end

      # Sporadic SSL errors keep causing test failures so there are anti-SSL workarounds here
      def generate_files
        system("gem list '^rails$' --installed --version '#{version_constraint}' || " \
                 "gem install rails --clear-sources --source http://rubygems.org --version '#{version_constraint}'")

        @version = RailsVersion.new(`ruby -e 'puts Gem::Specification.find_by_name("rails", "#{version_constraint}").version'`.chomp)

        skips = %w(--skip-bundle --skip-javascript --skip-sprockets)
        skips << "--skip-spring" if version.bundles_spring?

        system("rails _#{version}_ new #{application.root} #{skips.join(' ')}")
        raise "application generation failed" unless application.exists?

        FileUtils.mkdir_p(application.gem_home)
        FileUtils.mkdir_p(application.user_home)
        FileUtils.rm_rf(application.path("test/performance"))

        append_to_file(application.gemfile, "gem 'spring', '#{Spring::VERSION}'")

        if version.needs_testunit?
          append_to_file(application.gemfile, "gem 'spring-commands-testunit'")
        end

        rewrite_file(application.gemfile) do |c|
          c.sub!("https://rubygems.org", "http://rubygems.org")
          c.gsub!(/(gem '(byebug|web-console|sdoc|jbuilder)')/, "# \\1")
          c
        end


        if application.path("bin").exist?
          FileUtils.cp_r(application.path("bin"), application.path("bin_original"))
        end
      end

      def rewrite_file(file)
        File.write(file, yield(file.read))
      end

      def append_to_file(file, add)
        rewrite_file(file) { |c| c << "#{add}\n" }
      end

      def generate_if_missing
        generate unless application.exists?
      end

      def install_spring
        return if @installed

        build_and_install_gems

        application.bundle

        FileUtils.rm_rf application.path("bin")

        if application.path("bin_original").exist?
          FileUtils.cp_r application.path("bin_original"), application.path("bin")
        end

        application.run! "#{application.spring} binstub --all"
        @installed = true
      end

      def manually_built_gems
        %w(spring)
      end

      def build_and_install_gems
        manually_built_gems.each do |name|
          spec = Gem::Specification.find_by_name(name)

          FileUtils.cd(spec.gem_dir) do
            FileUtils.rm(Dir.glob("#{name}-*.gem"))
            system("gem build #{name}.gemspec 2>&1")
          end

          application.run! "gem install #{spec.gem_dir}/#{name}-*.gem --no-ri --no-rdoc", timeout: nil
        end
      end

      def copy_to(path)
        system("rm -rf #{path}")
        system("cp -r #{application.root} #{path}")
      end

      def generate_scaffold
        application.run! "bundle exec rails g scaffold post title:string"
        application.run! "bundle exec rake db:migrate db:test:clone"
      end

      def gemspec(name)
        "#{Gem::Specification.find_by_name(name).gem_dir}/#{name}.gemspec"
      end
    end
  end
end
