# frozen_string_literal: true

require "csv"
require "fileutils"

module RendererHarness
  module Reporters
    module CsvReporter
      LATENCY_HEADERS = %w[
        t_started_ms latency_ms bytes_in bytes_out ok error http_status scenario thread_id
      ].freeze

      module_function

      def write_latency(path, results)
        FileUtils.mkdir_p(File.dirname(path))
        CSV.open(path, "w") do |csv|
          csv << LATENCY_HEADERS
          results.each do |r|
            csv << LATENCY_HEADERS.map { |h| r[h.to_sym] }
          end
        end
      end

      def write_memory(path, rows)
        FileUtils.mkdir_p(File.dirname(path))
        return if rows.empty?

        headers = rows.first.keys.map(&:to_s)
        CSV.open(path, "w") do |csv|
          csv << headers
          rows.each { |row| csv << headers.map { |h| row[h.to_sym] } }
        end
      end
    end
  end
end
