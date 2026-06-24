#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "oj"
  gem "json"
end

require "json"
require "oj"
require "securerandom"

module JsonBenchmark
  def self.random_string(length)
    SecureRandom.alphanumeric(length)
  end

  def self.mixed_realistic(users:, posts_per_user:, comments_per_post:)
    {
      "meta" => {
        "generated_at" => Time.now.to_s,
        "version" => "1.0.0",
        "request_id" => SecureRandom.uuid
      },
      "users" => users.times.map do |u|
        {
          "id" => u,
          "name" => "User #{random_string(8)}",
          "email" => "user#{u}@example.com",
          "profile" => {
            "bio" => random_string(200),
            "avatar_url" => "https://example.com/avatars/#{u}.jpg",
            "settings" => {
              "theme" => %w[light dark auto].sample,
              "notifications" => { "email" => true, "push" => false },
              "privacy" => { "show_email" => false, "show_activity" => true }
            }
          },
          "posts" => posts_per_user.times.map do |p|
            {
              "id" => u * 1000 + p,
              "title" => "Post #{random_string(20)}",
              "body" => random_string(500),
              "tags" => 3.times.map { random_string(10) },
              "comments" => comments_per_post.times.map do |c|
                {
                  "id" => u * 100_000 + p * 100 + c,
                  "author" => "Commenter #{c}",
                  "text" => random_string(100),
                  "likes" => rand(100)
                }
              end
            }
          end
        }
      end
    }
  end

  def self.run_timing(data, iterations)
    # Warm up
    5.times do
      JSON.generate(data)
      Oj.dump(data, mode: :compat)
    end

    json_times = iterations.times.map do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      JSON.generate(data)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end

    oj_times = iterations.times.map do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Oj.dump(data, mode: :compat)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end

    {
      json_avg: (json_times.sum / iterations * 1000).round(3),
      json_median: (json_times.sort[iterations / 2] * 1000).round(3),
      oj_avg: (oj_times.sum / iterations * 1000).round(3),
      oj_median: (oj_times.sort[iterations / 2] * 1000).round(3)
    }
  end

  def self.run
    puts "Ruby: #{RUBY_VERSION} (#{RUBY_PLATFORM})"
    puts "JSON gem: #{JSON::VERSION}"
    puts "Oj gem: #{Oj::VERSION}"
    puts

    scenarios = {
      "small_1kb" => mixed_realistic(users: 1, posts_per_user: 1, comments_per_post: 1),
      "medium_75kb" => mixed_realistic(users: 10, posts_per_user: 5, comments_per_post: 5),
      "large_1mb" => mixed_realistic(users: 50, posts_per_user: 10, comments_per_post: 10),
      "mega_4mb" => mixed_realistic(users: 100, posts_per_user: 20, comments_per_post: 10),
    }

    results = {}
    scenarios.each do |name, data|
      json_size = JSON.generate(data).bytesize
      size_label = json_size < 1024 ? "#{json_size} B" :
                   json_size < 1024*1024 ? "#{(json_size/1024.0).round(1)} KB" :
                   "#{(json_size/1024.0/1024.0).round(2)} MB"

      timing = run_timing(data, 50)
      speedup = (timing[:json_avg] / timing[:oj_avg]).round(2)

      results[name] = timing.merge(size: size_label, speedup: speedup)

      winner = speedup > 1 ? "Oj" : "JSON"
      factor = speedup > 1 ? speedup : (1.0/speedup).round(2)

      puts "#{name} (#{size_label}):"
      puts "  JSON.generate: #{timing[:json_avg]} ms (median: #{timing[:json_median]} ms)"
      puts "  Oj.dump:       #{timing[:oj_avg]} ms (median: #{timing[:oj_median]} ms)"
      puts "  Winner: #{winner} by #{factor}x"
      puts
    end

    # Output CSV-style summary for easy comparison
    puts "CSV_START"
    puts "scenario,size,json_avg_ms,json_median_ms,oj_avg_ms,oj_median_ms,oj_speedup"
    results.each do |name, r|
      puts "#{name},#{r[:size]},#{r[:json_avg]},#{r[:json_median]},#{r[:oj_avg]},#{r[:oj_median]},#{r[:speedup]}"
    end
    puts "CSV_END"
  end
end

JsonBenchmark.run
