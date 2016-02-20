require 'yaml'
require 'securerandom'

module Coveralls
  module Configuration

    def self.configuration
      config = {
        :environment => self.relevant_env,
        :git => git
      }
      yml = self.yaml_config
      if yml
        config[:configuration] = yml
        config[:repo_token] = yml['repo_token'] || yml['repo_secret_token']
      end
      if ENV['COVERALLS_REPO_TOKEN']
        config[:repo_token] = ENV['COVERALLS_REPO_TOKEN']
      end
      if ENV['COVERALLS_PARALLEL'] && ENV['COVERALLS_PARALLEL'] != "false"
        config[:parallel] = true
      end
      if ENV['TRAVIS']
        set_service_params_for_travis(config, yml ? yml['service_name'] : nil)
      elsif ENV['CIRCLECI']
        set_service_params_for_circleci(config)
      elsif ENV['SEMAPHORE']
        set_service_params_for_semaphore(config)
      elsif ENV['JENKINS_URL']
        set_service_params_for_jenkins(config)
      elsif ENV['APPVEYOR']
        set_service_params_for_appveyor(config)
      elsif ENV['TDDIUM']
        set_service_params_for_tddium(config)
      elsif ENV['COVERALLS_RUN_LOCALLY'] || Coveralls.testing
        set_service_params_for_coveralls_local(config)
      end

      # standardized env vars
      set_standard_service_params_for_generic_ci(config)

      config
    end

    def self.set_service_params_for_travis(config, service_name)
      config[:service_job_id] = ENV['TRAVIS_JOB_ID']
      config[:service_pull_request] = ENV['TRAVIS_PULL_REQUEST'] unless ENV['TRAVIS_PULL_REQUEST'] == 'false'
      config[:service_name]   = service_name || 'travis-ci'
    end

    def self.set_service_params_for_circleci(config)
      config[:service_name]         = 'circleci'
      config[:service_number]       = ENV['CIRCLE_BUILD_NUM']
      config[:service_pull_request] = (ENV['CI_PULL_REQUEST'] || "")[/(\d+)$/,1]
      config[:parallel]             = ENV['CIRCLE_NODE_TOTAL'].to_i > 1
      config[:service_job_number]   = ENV['CIRCLE_NODE_INDEX']
    end

    def self.set_service_params_for_semaphore(config)
      config[:service_name]         = 'semaphore'
      config[:service_number]       = ENV['SEMAPHORE_BUILD_NUMBER']
      config[:service_pull_request] = ENV['PULL_REQUEST_NUMBER']
    end

    def self.set_service_params_for_jenkins(config)
      config[:service_name]   = 'jenkins'
      config[:service_number] = ENV['BUILD_NUMBER']
    end

    def self.set_service_params_for_appveyor(config)
      config[:service_name]   = 'appveyor'
      config[:service_number] = ENV['APPVEYOR_BUILD_VERSION']
      config[:service_branch] = ENV['APPVEYOR_REPO_BRANCH']
      config[:commit_sha] = ENV['APPVEYOR_REPO_COMMIT']
      repo_name = ENV['APPVEYOR_REPO_NAME']
      config[:service_build_url]  = 'https://ci.appveyor.com/project/%s/build/%s' % [repo_name, config[:service_number]]
    end

    def self.set_service_params_for_tddium(config)
      config[:service_name]         = 'tddium'
      config[:service_number]       = ENV['TDDIUM_SESSION_ID']
      config[:service_job_number]   = ENV['TDDIUM_TID']
      config[:service_pull_request] = ENV['TDDIUM_PR_ID']
      config[:service_branch]       = ENV['TDDIUM_CURRENT_BRANCH']
      config[:service_build_url]    = "https://ci.solanolabs.com/reports/#{ENV['TDDIUM_SESSION_ID']}"
    end

    def self.set_service_params_for_coveralls_local(config)
      config[:service_job_id]     = nil
      config[:service_name]       = 'coveralls-ruby'
      config[:service_event_type] = 'manual'
    end

    def self.set_standard_service_params_for_generic_ci(config)
      config[:service_name]         ||= ENV['CI_NAME']
      config[:service_number]       ||= ENV['CI_BUILD_NUMBER']
      config[:service_job_id]       ||= ENV['CI_JOB_ID']
      config[:service_build_url]    ||= ENV['CI_BUILD_URL']
      config[:service_branch]       ||= ENV['CI_BRANCH']
      config[:service_pull_request] ||= (ENV['CI_PULL_REQUEST'] || "")[/(\d+)$/,1]
    end

    def self.yaml_config
      if self.configuration_path && File.exist?(self.configuration_path)
        YAML::load_file(self.configuration_path)
      end
    end

    def self.configuration_path
      File.expand_path(File.join(self.root, ".coveralls.yml")) if self.root
    end

    def self.root
      pwd
    end

    def self.pwd
      Dir.pwd
    end

    def self.simplecov_root
      if defined?(::SimpleCov)
        ::SimpleCov.root
      end
    end

    def self.rails_root
      Rails.root.to_s
    rescue
      nil
    end

    def self.git
      hash = {}

      Dir.chdir(root) do

        hash[:head] = {
          :id => ENV.fetch("GIT_ID", `git log -1 --pretty=format:'%H'`),
          :author_name => ENV.fetch("GIT_AUTHOR_NAME", `git log -1 --pretty=format:'%aN'`),
          :author_email => ENV.fetch("GIT_AUTHOR_EMAIL", `git log -1 --pretty=format:'%ae'`),
          :committer_name => ENV.fetch("GIT_COMMITTER_NAME", `git log -1 --pretty=format:'%cN'`),
          :committer_email => ENV.fetch("GIT_COMMITTER_EMAIL", `git log -1 --pretty=format:'%ce'`),
          :message => ENV.fetch("GIT_MESSAGE", `git log -1 --pretty=format:'%s'`)
        }

        # Branch
        hash[:branch] = ENV.fetch("GIT_BRANCH", `git rev-parse --abbrev-ref HEAD`)

        # Remotes
        remotes = nil
        begin
          remotes = `git remote -v`.split(/\n/).map do |remote|
            splits = remote.split(" ").compact
            {:name => splits[0], :url => splits[1]}
          end.uniq
        rescue
        end
        hash[:remotes] = remotes

      end

      hash

    rescue Exception => e
      Coveralls::Output.puts "Coveralls git error:", :color => "red"
      Coveralls::Output.puts e.to_s, :color => "red"
      nil
    end

    def self.relevant_env
      hash = {
        :pwd => self.pwd,
        :rails_root => self.rails_root,
        :simplecov_root => simplecov_root,
        :gem_version => VERSION
      }

      hash.merge! begin
        if ENV['TRAVIS']
          {
            :travis_job_id => ENV['TRAVIS_JOB_ID'],
            :travis_pull_request => ENV['TRAVIS_PULL_REQUEST']
          }
        elsif ENV['CIRCLECI']
          {
            :circleci_build_num => ENV['CIRCLE_BUILD_NUM'],
            :branch => ENV['CIRCLE_BRANCH'],
            :commit_sha => ENV['CIRCLE_SHA1']
          }
        elsif ENV['JENKINS_URL']
          {
            :jenkins_build_num => ENV['BUILD_NUMBER'],
            :jenkins_build_url => ENV['BUILD_URL'],
            :branch => ENV['GIT_BRANCH'],
            :commit_sha => ENV['GIT_COMMIT']
          }
        elsif ENV['SEMAPHORE']
          {
            :branch => ENV['BRANCH_NAME'],
            :commit_sha => ENV['REVISION']
          }
        else
          {}
        end
      end

      hash
    end

  end
end
