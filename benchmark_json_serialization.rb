#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "oj"
  gem "benchmark-ips"
  gem "json" # stdlib, but explicit
end

require "json"
require "oj"
require "benchmark/ips"
require "securerandom"

module JsonBenchmark
  class DataGenerator
    def self.random_string(length)
      SecureRandom.alphanumeric(length)
    end

    def self.random_value
      case rand(4)
      when 0 then rand(1_000_000)
      when 1 then rand * 1000.0
      when 2 then [true, false].sample
      when 3 then random_string(rand(10..50))
      end
    end

    def self.flat_object(key_count:, value_size: :medium)
      val_length = case value_size
                   when :small then 10
                   when :medium then 100
                   when :large then 1000
                   end

      key_count.times.each_with_object({}) do |i, h|
        h["key_#{i}"] = random_string(val_length)
      end
    end

    def self.nested_object(depth:, breadth:, leaf_size: 50)
      return random_string(leaf_size) if depth <= 0

      breadth.times.each_with_object({}) do |i, h|
        h["level_#{depth}_key_#{i}"] = nested_object(
          depth: depth - 1,
          breadth: breadth,
          leaf_size: leaf_size
        )
      end
    end

    def self.array_of_objects(count:, keys_per_object:)
      count.times.map do |i|
        obj = { "id" => i, "uuid" => SecureRandom.uuid }
        (keys_per_object - 2).times do |j|
          obj["field_#{j}"] = random_value
        end
        obj
      end
    end

    def self.mixed_realistic(users:, posts_per_user:, comments_per_post:)
      {
        "meta" => {
          "generated_at" => Time.now.iso8601,
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
  end

  class Runner
    SCENARIOS = {
      # Flat objects with varying key counts
      "flat_10_keys" => -> { DataGenerator.flat_object(key_count: 10) },
      "flat_100_keys" => -> { DataGenerator.flat_object(key_count: 100) },
      "flat_1000_keys" => -> { DataGenerator.flat_object(key_count: 1000) },

      # Flat objects with varying value sizes
      "flat_100_small_vals" => -> { DataGenerator.flat_object(key_count: 100, value_size: :small) },
      "flat_100_medium_vals" => -> { DataGenerator.flat_object(key_count: 100, value_size: :medium) },
      "flat_100_large_vals" => -> { DataGenerator.flat_object(key_count: 100, value_size: :large) },

      # Nested objects with varying depth
      "nested_depth2_breadth3" => -> { DataGenerator.nested_object(depth: 2, breadth: 3) },
      "nested_depth4_breadth3" => -> { DataGenerator.nested_object(depth: 4, breadth: 3) },
      "nested_depth6_breadth2" => -> { DataGenerator.nested_object(depth: 6, breadth: 2) },

      # Arrays of objects
      "array_10_objects" => -> { DataGenerator.array_of_objects(count: 10, keys_per_object: 10) },
      "array_100_objects" => -> { DataGenerator.array_of_objects(count: 100, keys_per_object: 10) },
      "array_1000_objects" => -> { DataGenerator.array_of_objects(count: 1000, keys_per_object: 10) },

      # Realistic mixed scenarios (simulating React props)
      "realistic_small" => -> { DataGenerator.mixed_realistic(users: 1, posts_per_user: 2, comments_per_post: 2) },
      "realistic_medium" => -> { DataGenerator.mixed_realistic(users: 10, posts_per_user: 5, comments_per_post: 5) },
      "realistic_large" => -> { DataGenerator.mixed_realistic(users: 50, posts_per_user: 10, comments_per_post: 10) },
      "realistic_mega" => -> { DataGenerator.mixed_realistic(users: 100, posts_per_user: 20, comments_per_post: 10) },
    }.freeze

    def initialize
      @results = []
    end

    def run_all
      puts "=" * 80
      puts "JSON Serialization Benchmark: JSON.generate vs Oj.dump"
      puts "=" * 80
      puts "Ruby: #{RUBY_VERSION}"
      puts "Oj version: #{Oj::VERSION}"
      puts "JSON version: #{JSON::VERSION}"
      puts "=" * 80
      puts

      SCENARIOS.each do |name, generator|
        run_scenario(name, generator)
      end

      print_summary
    end

    private

    def run_scenario(name, generator)
      data = generator.call
      json_output = JSON.generate(data)
      oj_output = Oj.dump(data, mode: :compat)

      size_kb = (json_output.bytesize / 1024.0).round(2)
      outputs_match = json_output == oj_output

      puts "-" * 80
      puts "Scenario: #{name}"
      puts "  JSON size: #{size_kb} KB (#{json_output.bytesize} bytes)"
      puts "  Outputs match: #{outputs_match ? 'YES' : 'NO (checking semantic equivalence...)'}"

      unless outputs_match
        json_parsed = JSON.parse(json_output)
        oj_parsed = JSON.parse(oj_output)
        semantic_match = json_parsed == oj_parsed
        puts "  Semantic equivalence: #{semantic_match ? 'YES' : 'NO - INCOMPATIBLE!'}"
      end

      puts

      json_ips = nil
      oj_ips = nil

      Benchmark.ips do |x|
        x.config(time: 2, warmup: 0.5)

        x.report("JSON.generate") do
          JSON.generate(data)
        end

        x.report("data.to_json") do
          data.to_json
        end

        x.report("Oj.dump(:compat)") do
          Oj.dump(data, mode: :compat)
        end

        x.report("Oj.dump(:rails)") do
          Oj.dump(data, mode: :rails)
        end

        x.compare!
      end

      puts
    end

    def print_summary
      puts "=" * 80
      puts "SUMMARY"
      puts "=" * 80
      puts
      puts "Key findings will be displayed above in each scenario's comparison."
      puts
      puts "Interpretation guide:"
      puts "  - Higher i/s (iterations per second) = faster"
      puts "  - The 'x slower' comparison shows relative performance"
      puts "  - Oj modes: :compat (JSON-compatible), :rails (ActiveSupport compatible)"
      puts
    end
  end
end

# Also run a quick timing comparison for absolute times
module QuickTiming
  def self.run
    puts "=" * 80
    puts "ABSOLUTE TIMING COMPARISON (single runs, larger data)"
    puts "=" * 80
    puts

    # Generate a ~1MB payload similar to the issue description
    large_data = JsonBenchmark::DataGenerator.mixed_realistic(
      users: 200,
      posts_per_user: 25,
      comments_per_post: 10
    )

    json_output = JSON.generate(large_data)
    puts "Large payload size: #{(json_output.bytesize / 1024.0 / 1024.0).round(2)} MB"
    puts

    iterations = 100

    # Warm up
    5.times do
      JSON.generate(large_data)
      Oj.dump(large_data, mode: :compat)
    end

    # Time JSON.generate
    json_times = iterations.times.map do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      JSON.generate(large_data)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end

    # Time Oj.dump
    oj_times = iterations.times.map do
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Oj.dump(large_data, mode: :compat)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end

    json_avg = (json_times.sum / iterations * 1000).round(3)
    json_min = (json_times.min * 1000).round(3)
    json_max = (json_times.max * 1000).round(3)
    json_median = (json_times.sort[iterations / 2] * 1000).round(3)

    oj_avg = (oj_times.sum / iterations * 1000).round(3)
    oj_min = (oj_times.min * 1000).round(3)
    oj_max = (oj_times.max * 1000).round(3)
    oj_median = (oj_times.sort[iterations / 2] * 1000).round(3)

    speedup = (json_avg / oj_avg).round(2)
    savings_ms = (json_avg - oj_avg).round(3)

    puts "Results over #{iterations} iterations:"
    puts
    puts "JSON.generate:"
    puts "  Average: #{json_avg} ms"
    puts "  Median:  #{json_median} ms"
    puts "  Min:     #{json_min} ms"
    puts "  Max:     #{json_max} ms"
    puts
    puts "Oj.dump(:compat):"
    puts "  Average: #{oj_avg} ms"
    puts "  Median:  #{oj_median} ms"
    puts "  Min:     #{oj_min} ms"
    puts "  Max:     #{oj_max} ms"
    puts
    puts "Speedup: #{speedup}x faster with Oj"
    puts "Absolute savings: #{savings_ms} ms per serialization"
    puts
  end
end

if __FILE__ == $PROGRAM_NAME
  # Run the quick timing first (most relevant to the issue hypothesis)
  QuickTiming.run

  # Then run detailed IPS benchmarks
  JsonBenchmark::Runner.new.run_all
end
