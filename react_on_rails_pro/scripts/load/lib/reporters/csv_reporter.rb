# frozen_string_literal: true

require "csv"
require "fileutils"

module RendererHarness
  module Reporters
    module CsvReporter
      LATENCY_HEADERS = %w[
        t_started_ms latency_ms bytes_in bytes_out ok error http_status scenario thread_id
      ].freeze
      MEMORY_HEADERS = %w[
        t_seconds rails_rss_kb renderer_rss_kb gc_heap_live_slots
        gc_total_allocated_objects gc_malloc_increase_bytes gc_oldmalloc_increase_bytes
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

        headers = memory_headers(rows)
        CSV.open(path, "w") do |csv|
          csv << headers
          rows.each { |row| csv << headers.map { |h| row[h.to_sym] } }
        end
      end

      def memory_headers(rows)
        row_headers = rows.flat_map(&:keys).map(&:to_s).uniq
        known_headers = MEMORY_HEADERS.select { |header| row_headers.include?(header) }
        extra_headers = row_headers - MEMORY_HEADERS
        known_headers + extra_headers.sort
      end
    end
  end
end
