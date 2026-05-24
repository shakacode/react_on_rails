# Renderer Transport Load and Memory Harness — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Ruby load-and-memory harness that exercises the real `ReactOnRailsPro::Request` transport against the dummy node renderer, so HTTPX vs async-http can be compared on latency, throughput, and memory growth.

**Architecture:** Standalone harness lives at `react_on_rails_pro/scripts/load/`. Invoked via `bin/rails runner` from the dummy app so Rails + `ReactOnRailsPro.configuration` are already populated. Three scenarios (`standard_render`, `streaming_render`, `incremental_async`) drive HTTP traffic through `ReactOnRailsPro::Request`. A background thread samples RSS + `GC.stat`. Output: JSON summary + per-request CSV + memory CSV + terminal summary, written under `tmp/load-tests/<UTC-timestamp>/`.

**Tech Stack:** Ruby (stdlib `optparse`, `csv`, `json`, `open3`), Ruby threads for concurrency, RSpec for harness unit tests. No new gem dependencies.

**Reference spec:** `docs/superpowers/specs/2026-05-23-renderer-load-harness-design.md`

---

## File Map

**Create (harness lib):**

- `react_on_rails_pro/scripts/load/renderer_harness.rb` — CLI entry, dispatches to Harness
- `react_on_rails_pro/scripts/load/lib/config.rb` — parsed CLI flags into a frozen struct
- `react_on_rails_pro/scripts/load/lib/request_result.rb` — per-request outcome struct
- `react_on_rails_pro/scripts/load/lib/metrics.rb` — percentile, RPS, slope math
- `react_on_rails_pro/scripts/load/lib/memory_sampler.rb` — background RSS + GC.stat sampler
- `react_on_rails_pro/scripts/load/lib/runner.rb` — thread-pool driver
- `react_on_rails_pro/scripts/load/lib/harness.rb` — orchestrator (warmup → run → drain → report)
- `react_on_rails_pro/scripts/load/lib/reporters/json_reporter.rb`
- `react_on_rails_pro/scripts/load/lib/reporters/csv_reporter.rb`
- `react_on_rails_pro/scripts/load/lib/reporters/terminal_reporter.rb`
- `react_on_rails_pro/scripts/load/lib/scenarios/base.rb`
- `react_on_rails_pro/scripts/load/lib/scenarios/standard_render.rb`
- `react_on_rails_pro/scripts/load/lib/scenarios/streaming_render.rb`
- `react_on_rails_pro/scripts/load/lib/scenarios/incremental_async.rb`

**Create (wrapper + docs):**

- `react_on_rails_pro/spec/dummy/bin/renderer-harness` — shell wrapper that invokes `bin/rails runner ../scripts/load/renderer_harness.rb -- "$@"`
- `react_on_rails_pro/scripts/load/README.md`

**Create (tests):**

- `react_on_rails_pro/spec/load/spec_helper.rb` — minimal helper (no Rails)
- `react_on_rails_pro/spec/load/metrics_spec.rb`
- `react_on_rails_pro/spec/load/reporters_spec.rb`
- `react_on_rails_pro/spec/load/memory_sampler_spec.rb`

**Modify:**

- `react_on_rails_pro/lib/react_on_rails_pro/constants.rb` — add `RENDERER_TRANSPORT_ENV` and `DEFAULT_RENDERER_TRANSPORT` constants

---

## Task 1: Scaffold skeleton (RequestResult + Config)

**Files:**

- Create: `react_on_rails_pro/scripts/load/lib/request_result.rb`
- Create: `react_on_rails_pro/scripts/load/lib/config.rb`

- [ ] **Step 1: Create `request_result.rb`**

```ruby
# frozen_string_literal: true

module RendererHarness
  RequestResult = Struct.new(
    :latency_ms,
    :bytes_in,
    :bytes_out,
    :ok,
    :error,
    :http_status,
    :scenario,
    :thread_id,
    :t_started_ms,
    keyword_init: true
  )
end
```

- [ ] **Step 2: Create `config.rb`**

```ruby
# frozen_string_literal: true

require "optparse"

module RendererHarness
  Config = Struct.new(
    :scenario,
    :requests,
    :duration,
    :concurrency,
    :warmup,
    :mix,
    :increments,
    :mem_interval,
    :renderer_pid,
    :output_dir,
    :smoke,
    keyword_init: true
  ) do
    def self.parse(argv)
      opts = {
        scenario: "standard_render",
        requests: nil,
        duration: nil,
        concurrency: 1,
        warmup: 5,
        mix: "small",
        increments: 5,
        mem_interval: 1.0,
        renderer_pid: nil,
        output_dir: nil,
        smoke: false
      }
      parser = OptionParser.new do |o|
        o.banner = "Usage: renderer_harness [options]"
        o.on("--scenario NAME", String) { |v| opts[:scenario] = v }
        o.on("--requests N", Integer) { |v| opts[:requests] = v }
        o.on("--duration SECONDS", Integer) { |v| opts[:duration] = v }
        o.on("--concurrency N", Integer) { |v| opts[:concurrency] = v }
        o.on("--warmup N", Integer) { |v| opts[:warmup] = v }
        o.on("--mix MIX", %w[small medium large]) { |v| opts[:mix] = v }
        o.on("--increments N", Integer) { |v| opts[:increments] = v }
        o.on("--mem-interval SECONDS", Float) { |v| opts[:mem_interval] = v }
        o.on("--renderer-pid PID", Integer) { |v| opts[:renderer_pid] = v }
        o.on("--output-dir PATH", String) { |v| opts[:output_dir] = v }
        o.on("--smoke") { opts[:smoke] = true }
        o.on("-h", "--help") { puts o; exit 0 }
      end
      parser.parse!(argv)
      apply_smoke_preset!(opts) if opts[:smoke]
      validate!(opts)
      new(**opts).freeze
    end

    def self.apply_smoke_preset!(opts)
      opts[:scenario] = "standard_render"
      opts[:requests] = 10
      opts[:concurrency] = 1
      opts[:warmup] = 0
    end

    def self.validate!(opts)
      unless %w[standard_render streaming_render incremental_async].include?(opts[:scenario])
        raise ArgumentError, "unknown scenario: #{opts[:scenario]}"
      end
      if opts[:requests].nil? && opts[:duration].nil?
        raise ArgumentError, "must provide --requests or --duration (or --smoke)"
      end
      if opts[:requests] && opts[:duration]
        raise ArgumentError, "--requests and --duration are mutually exclusive"
      end
      raise ArgumentError, "--concurrency must be >= 1" if opts[:concurrency] < 1
    end
  end
end
```

- [ ] **Step 3: Commit**

```bash
git add react_on_rails_pro/scripts/load/lib/request_result.rb \
        react_on_rails_pro/scripts/load/lib/config.rb
git commit -m "feat(pro): scaffold renderer load harness (RequestResult, Config)"
```

---

## Task 2: Metrics (TDD)

**Files:**

- Create: `react_on_rails_pro/spec/load/spec_helper.rb`
- Create: `react_on_rails_pro/spec/load/metrics_spec.rb`
- Create: `react_on_rails_pro/scripts/load/lib/metrics.rb`

- [ ] **Step 1: Create `spec/load/spec_helper.rb`**

```ruby
# frozen_string_literal: true

require "rspec"

$LOAD_PATH.unshift(File.expand_path("../../scripts/load/lib", __dir__))

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
```

- [ ] **Step 2: Write failing test in `spec/load/metrics_spec.rb`**

```ruby
# frozen_string_literal: true

require "spec_helper"
require "metrics"
require "request_result"

RSpec.describe RendererHarness::Metrics do
  describe ".percentile" do
    it "returns the only sample when given a single value" do
      expect(described_class.percentile([42.0], 50)).to eq(42.0)
    end

    it "returns nil for an empty sample set" do
      expect(described_class.percentile([], 99)).to be_nil
    end

    it "returns p50 of a sorted series" do
      samples = (1..100).map(&:to_f)
      expect(described_class.percentile(samples, 50)).to be_within(1.0).of(50.0)
    end

    it "returns p99 of a known series" do
      samples = (1..100).map(&:to_f)
      expect(described_class.percentile(samples, 99)).to be >= 99.0
    end

    it "handles identical samples" do
      expect(described_class.percentile([5.0] * 20, 95)).to eq(5.0)
    end
  end

  describe ".rps" do
    it "returns count / elapsed seconds" do
      expect(described_class.rps(count: 100, elapsed_seconds: 4.0)).to eq(25.0)
    end

    it "returns 0.0 when elapsed is 0" do
      expect(described_class.rps(count: 100, elapsed_seconds: 0)).to eq(0.0)
    end
  end

  describe ".slope_mb_per_min" do
    it "is positive for monotonically rising RSS" do
      # 10 samples 1s apart, RSS rises 1MB per second = 60 MB/min
      series = (0..9).map { |i| [i.to_f, (100 + i) * 1024.0] } # kB units like ps
      slope = described_class.slope_mb_per_min(series)
      expect(slope).to be_within(0.5).of(60.0)
    end

    it "is 0 for a flat series" do
      series = (0..9).map { |i| [i.to_f, 100_000.0] }
      expect(described_class.slope_mb_per_min(series)).to be_within(0.001).of(0.0)
    end

    it "returns 0 for fewer than 2 samples" do
      expect(described_class.slope_mb_per_min([[1.0, 1000.0]])).to eq(0.0)
    end
  end

  describe ".summarize_latencies" do
    it "returns a hash with p50/p95/p99/p99_9/max/mean/count" do
      results = (1..100).map { |i| RendererHarness::RequestResult.new(latency_ms: i.to_f, ok: true) }
      summary = described_class.summarize_latencies(results)
      expect(summary).to include(:p50, :p95, :p99, :p99_9, :max, :mean, :count)
      expect(summary[:count]).to eq(100)
      expect(summary[:max]).to eq(100.0)
    end
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd react_on_rails_pro && bundle exec rspec spec/load/metrics_spec.rb`
Expected: FAIL with "cannot load such file -- metrics"

- [ ] **Step 4: Implement `scripts/load/lib/metrics.rb`**

```ruby
# frozen_string_literal: true

module RendererHarness
  module Metrics
    module_function

    def percentile(samples, pct)
      return nil if samples.empty?

      sorted = samples.sort
      rank = (pct / 100.0) * (sorted.length - 1)
      lower = rank.floor
      upper = rank.ceil
      return sorted[lower] if lower == upper

      sorted[lower] + ((sorted[upper] - sorted[lower]) * (rank - lower))
    end

    def rps(count:, elapsed_seconds:)
      return 0.0 if elapsed_seconds.to_f.zero?

      count.to_f / elapsed_seconds
    end

    # series: Array of [time_seconds, rss_kb] pairs
    # Returns slope in MB/min using simple least-squares regression.
    def slope_mb_per_min(series)
      return 0.0 if series.length < 2

      n = series.length
      sx = series.sum { |x, _| x }
      sy = series.sum { |_, y| y }
      sxx = series.sum { |x, _| x * x }
      sxy = series.sum { |x, y| x * y }
      denom = (n * sxx) - (sx * sx)
      return 0.0 if denom.zero?

      slope_kb_per_sec = ((n * sxy) - (sx * sy)) / denom
      (slope_kb_per_sec / 1024.0) * 60.0
    end

    def summarize_latencies(results)
      ok = results.select(&:ok)
      latencies = ok.map(&:latency_ms)
      {
        count: results.length,
        ok_count: ok.length,
        failures: results.length - ok.length,
        mean: latencies.empty? ? 0.0 : latencies.sum / latencies.length,
        p50: percentile(latencies, 50),
        p90: percentile(latencies, 90),
        p95: percentile(latencies, 95),
        p99: percentile(latencies, 99),
        p99_9: percentile(latencies, 99.9),
        max: latencies.max || 0.0
      }
    end
  end
end
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd react_on_rails_pro && bundle exec rspec spec/load/metrics_spec.rb`
Expected: all examples pass

- [ ] **Step 6: Commit**

```bash
git add react_on_rails_pro/spec/load/spec_helper.rb \
        react_on_rails_pro/spec/load/metrics_spec.rb \
        react_on_rails_pro/scripts/load/lib/metrics.rb
git commit -m "feat(pro): renderer harness — metrics (percentiles, RPS, slope)"
```

---

## Task 3: MemorySampler (TDD)

**Files:**

- Create: `react_on_rails_pro/spec/load/memory_sampler_spec.rb`
- Create: `react_on_rails_pro/scripts/load/lib/memory_sampler.rb`

- [ ] **Step 1: Write failing test**

```ruby
# frozen_string_literal: true

require "spec_helper"
require "memory_sampler"

RSpec.describe RendererHarness::MemorySampler do
  describe "#sample_rss_kb" do
    it "parses ps output and returns integer kB" do
      sampler = described_class.new(pids: { rails: 1234 })
      allow(sampler).to receive(:run_ps).with(1234).and_return("  102400\n")
      expect(sampler.sample_rss_kb(1234)).to eq(102_400)
    end

    it "returns nil when ps returns nothing" do
      sampler = described_class.new(pids: { rails: 1234 })
      allow(sampler).to receive(:run_ps).with(1234).and_return("")
      expect(sampler.sample_rss_kb(1234)).to be_nil
    end

    it "returns nil when ps raises" do
      sampler = described_class.new(pids: { rails: 1234 })
      allow(sampler).to receive(:run_ps).with(1234).and_raise(Errno::ESRCH)
      expect(sampler.sample_rss_kb(1234)).to be_nil
    end
  end

  describe "#gc_snapshot" do
    it "returns a hash with the four tracked keys" do
      sampler = described_class.new(pids: { rails: Process.pid })
      snap = sampler.gc_snapshot
      expect(snap.keys).to contain_exactly(
        :heap_live_slots, :total_allocated_objects, :malloc_increase_bytes, :oldmalloc_increase_bytes
      )
      expect(snap.values).to all(be_a(Integer))
    end
  end

  describe "#sample_once" do
    it "returns a row including t_seconds, rails_rss_kb, and gc.* fields" do
      sampler = described_class.new(pids: { rails: 1234 }, start_time: Time.now - 5)
      allow(sampler).to receive(:run_ps).with(1234).and_return("100\n")
      row = sampler.sample_once
      expect(row[:t_seconds]).to be_within(0.5).of(5.0)
      expect(row[:rails_rss_kb]).to eq(100)
      expect(row.keys).to include(:gc_heap_live_slots)
    end

    it "includes renderer_rss_kb when renderer pid is set" do
      sampler = described_class.new(pids: { rails: 1234, renderer: 5678 })
      allow(sampler).to receive(:run_ps).with(1234).and_return("100\n")
      allow(sampler).to receive(:run_ps).with(5678).and_return("4000\n")
      row = sampler.sample_once
      expect(row[:renderer_rss_kb]).to eq(4000)
    end
  end
end
```

- [ ] **Step 2: Verify it fails**

Run: `cd react_on_rails_pro && bundle exec rspec spec/load/memory_sampler_spec.rb`
Expected: FAIL with "cannot load such file -- memory_sampler"

- [ ] **Step 3: Implement `scripts/load/lib/memory_sampler.rb`**

```ruby
# frozen_string_literal: true

require "open3"

module RendererHarness
  class MemorySampler
    GC_KEYS = %i[heap_live_slots total_allocated_objects malloc_increase_bytes oldmalloc_increase_bytes].freeze

    attr_reader :pids, :rows

    def initialize(pids:, start_time: Time.now)
      @pids = pids                   # Hash like { rails: pid, renderer: pid_or_nil }
      @start_time = start_time
      @rows = []
      @thread = nil
      @stop = false
    end

    def start_background(interval_seconds:)
      @thread = Thread.new do
        until @stop
          @rows << sample_once
          sleep(interval_seconds)
        end
      end
    end

    def stop_background
      @stop = true
      @thread&.join
    end

    def sample_once
      row = { t_seconds: Time.now - @start_time }
      pids.each do |label, pid|
        next if pid.nil?

        row[:"#{label}_rss_kb"] = sample_rss_kb(pid)
      end
      gc_snapshot.each { |k, v| row[:"gc_#{k}"] = v }
      row
    end

    def sample_rss_kb(pid)
      out = run_ps(pid)
      return nil if out.nil? || out.strip.empty?

      out.strip.to_i
    rescue Errno::ESRCH, Errno::ENOENT
      nil
    end

    def gc_snapshot
      stat = GC.stat
      GC_KEYS.to_h { |k| [k, stat[k].to_i] }
    end

    private

    def run_ps(pid)
      out, _err, status = Open3.capture3("ps", "-o", "rss=", "-p", pid.to_s)
      status.success? ? out : nil
    end
  end
end
```

- [ ] **Step 4: Verify tests pass**

Run: `cd react_on_rails_pro && bundle exec rspec spec/load/memory_sampler_spec.rb`
Expected: all examples pass

- [ ] **Step 5: Commit**

```bash
git add react_on_rails_pro/spec/load/memory_sampler_spec.rb \
        react_on_rails_pro/scripts/load/lib/memory_sampler.rb
git commit -m "feat(pro): renderer harness — memory sampler (RSS + GC.stat)"
```

---

## Task 4: Reporters (TDD)

**Files:**

- Create: `react_on_rails_pro/spec/load/reporters_spec.rb`
- Create: `react_on_rails_pro/scripts/load/lib/reporters/json_reporter.rb`
- Create: `react_on_rails_pro/scripts/load/lib/reporters/csv_reporter.rb`
- Create: `react_on_rails_pro/scripts/load/lib/reporters/terminal_reporter.rb`

- [ ] **Step 1: Write failing test**

```ruby
# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "json"
require "csv"
require "request_result"
require "reporters/json_reporter"
require "reporters/csv_reporter"
require "reporters/terminal_reporter"

RSpec.describe "Reporters" do
  let(:results) do
    [
      RendererHarness::RequestResult.new(
        latency_ms: 12.0, bytes_in: 1024, bytes_out: 256, ok: true,
        error: nil, http_status: 200, scenario: "standard_render",
        thread_id: 0, t_started_ms: 1.0
      ),
      RendererHarness::RequestResult.new(
        latency_ms: 0.0, bytes_in: 0, bytes_out: 0, ok: false,
        error: "timeout", http_status: nil, scenario: "standard_render",
        thread_id: 0, t_started_ms: 2.0
      )
    ]
  end

  let(:memory_rows) do
    [
      { t_seconds: 0.0, rails_rss_kb: 100_000, gc_heap_live_slots: 1000 },
      { t_seconds: 1.0, rails_rss_kb: 101_000, gc_heap_live_slots: 1100 }
    ]
  end

  let(:summary_payload) do
    {
      scenario: "standard_render",
      transport: "httpx",
      concurrency: 1,
      elapsed_seconds: 5.0,
      requests: { count: 2, failures: 1, rps: 0.4 },
      latency_ms: { p50: 12.0, p95: 12.0, p99: 12.0, max: 12.0, mean: 12.0 },
      memory: { rails_slope_mb_per_min: 0.5 }
    }
  end

  describe RendererHarness::Reporters::JsonReporter do
    it "writes summary.json with the payload" do
      Dir.mktmpdir do |dir|
        described_class.write(File.join(dir, "summary.json"), summary_payload)
        parsed = JSON.parse(File.read(File.join(dir, "summary.json")))
        expect(parsed["scenario"]).to eq("standard_render")
        expect(parsed["transport"]).to eq("httpx")
        expect(parsed["requests"]["count"]).to eq(2)
      end
    end
  end

  describe RendererHarness::Reporters::CsvReporter do
    it "writes latency.csv with one header + one row per result" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "latency.csv")
        described_class.write_latency(path, results)
        rows = CSV.read(path)
        expect(rows.first).to include("latency_ms", "ok", "scenario")
        expect(rows.length).to eq(3) # header + 2 results
      end
    end

    it "writes memory.csv with one header + one row per sample" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "memory.csv")
        described_class.write_memory(path, memory_rows)
        rows = CSV.read(path)
        expect(rows.first).to include("t_seconds", "rails_rss_kb")
        expect(rows.length).to eq(3) # header + 2 samples
      end
    end
  end

  describe RendererHarness::Reporters::TerminalReporter do
    it "prints a summary block including scenario, transport, RPS, p99" do
      out = StringIO.new
      described_class.print(out, summary_payload)
      text = out.string
      expect(text).to include("standard_render")
      expect(text).to include("httpx")
      expect(text).to include("RPS")
      expect(text).to include("p99")
    end
  end
end
```

- [ ] **Step 2: Verify failing**

Run: `cd react_on_rails_pro && bundle exec rspec spec/load/reporters_spec.rb`
Expected: FAIL with cannot-load errors

- [ ] **Step 3: Implement `scripts/load/lib/reporters/json_reporter.rb`**

```ruby
# frozen_string_literal: true

require "json"
require "fileutils"

module RendererHarness
  module Reporters
    module JsonReporter
      module_function

      def write(path, payload)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, JSON.pretty_generate(payload))
      end
    end
  end
end
```

- [ ] **Step 4: Implement `scripts/load/lib/reporters/csv_reporter.rb`**

```ruby
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
```

- [ ] **Step 5: Implement `scripts/load/lib/reporters/terminal_reporter.rb`**

```ruby
# frozen_string_literal: true

module RendererHarness
  module Reporters
    module TerminalReporter
      module_function

      def print(io, summary)
        io.puts "=== Renderer Load Harness Results ==="
        io.puts "Scenario: #{summary[:scenario]} | Concurrency: #{summary[:concurrency]} | Elapsed: #{format_secs(summary[:elapsed_seconds])}"
        io.puts "Transport: #{summary[:transport]}"
        io.puts
        req = summary[:requests]
        io.puts "Requests: #{req[:count]} (failures: #{req[:failures]})"
        io.puts "RPS: #{format('%.1f', req[:rps])}"
        io.puts
        lat = summary[:latency_ms]
        io.puts "Latency (ms):  p50=#{fmt(lat[:p50])}  p95=#{fmt(lat[:p95])}  p99=#{fmt(lat[:p99])}  max=#{fmt(lat[:max])}"
        if summary[:memory]
          mem = summary[:memory]
          io.puts "Rails RSS slope: #{format('%+.2f', mem[:rails_slope_mb_per_min] || 0)} MB/min"
          if mem[:renderer_slope_mb_per_min]
            io.puts "Renderer RSS slope: #{format('%+.2f', mem[:renderer_slope_mb_per_min])} MB/min"
          end
        end
        io.puts
        io.puts "Output: #{summary[:output_dir]}" if summary[:output_dir]
      end

      def fmt(value)
        return "n/a" if value.nil?

        format("%.1f", value)
      end

      def format_secs(s)
        return "n/a" if s.nil?

        "#{format('%.1f', s)}s"
      end
    end
  end
end
```

- [ ] **Step 6: Verify tests pass**

Run: `cd react_on_rails_pro && bundle exec rspec spec/load/reporters_spec.rb`
Expected: all examples pass

- [ ] **Step 7: Commit**

```bash
git add react_on_rails_pro/spec/load/reporters_spec.rb \
        react_on_rails_pro/scripts/load/lib/reporters/
git commit -m "feat(pro): renderer harness — JSON/CSV/terminal reporters"
```

---

## Task 5: Scenario base + StandardRender

**Files:**

- Create: `react_on_rails_pro/scripts/load/lib/scenarios/base.rb`
- Create: `react_on_rails_pro/scripts/load/lib/scenarios/standard_render.rb`

No unit tests for scenarios — they're verified by the end-to-end smoke run in Task 12.

- [ ] **Step 1: Implement `scripts/load/lib/scenarios/base.rb`**

```ruby
# frozen_string_literal: true

require "request_result"

module RendererHarness
  module Scenarios
    class Base
      MIX_PROPS_SIZES = { "small" => 200, "medium" => 10_000, "large" => 100_000 }.freeze

      attr_reader :config

      def initialize(config)
        @config = config
      end

      def name
        self.class.name.split("::").last.then { |s| s.gsub(/([A-Z])/) { "_#{Regexp.last_match(1).downcase}" }.sub(/^_/, "") }
      end

      def warmup(n)
        n.times { perform_request }
      end

      def perform_request
        raise NotImplementedError
      end

      def cleanup; end

      protected

      def filler_props
        size = MIX_PROPS_SIZES.fetch(config.mix)
        { "filler" => "x" * size }
      end

      def measure
        t0 = monotonic_ms
        t_started_ms = (Time.now.to_f * 1000)
        begin
          payload = yield
          RequestResult.new(
            latency_ms: monotonic_ms - t0,
            bytes_in: payload[:bytes_in] || 0,
            bytes_out: payload[:bytes_out] || 0,
            ok: true,
            error: nil,
            http_status: payload[:http_status],
            scenario: name,
            thread_id: Thread.current.object_id,
            t_started_ms: t_started_ms
          )
        rescue StandardError => e
          RequestResult.new(
            latency_ms: monotonic_ms - t0,
            bytes_in: 0,
            bytes_out: 0,
            ok: false,
            error: e.message,
            http_status: nil,
            scenario: name,
            thread_id: Thread.current.object_id,
            t_started_ms: t_started_ms
          )
        end
      end

      def monotonic_ms
        Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000.0
      end
    end
  end
end
```

- [ ] **Step 2: Implement `scripts/load/lib/scenarios/standard_render.rb`**

```ruby
# frozen_string_literal: true

require_relative "base"

module RendererHarness
  module Scenarios
    class StandardRender < Base
      JS_TEMPLATE = <<~JS
        (function(){
          var HelloWorld = ReactOnRails.getComponent('HelloWorld');
          var props = %<props>s;
          return ReactOnRails.serverRenderReactComponent({
            name: 'HelloWorld',
            domNodeId: 'HelloWorld-react-component',
            props: props,
            trace: false,
            renderingReturnsPromises: false
          });
        })()
      JS

      def perform_request
        js = format(JS_TEMPLATE, props: filler_props.to_json)
        measure do
          response = ReactOnRailsPro::Request.render_code(
            "/bundles/server-bundle.js/render",
            js,
            false
          )
          body = response.respond_to?(:body) ? response.body.to_s : response.to_s
          { http_status: response.respond_to?(:status) ? response.status : nil,
            bytes_in: body.bytesize, bytes_out: js.bytesize }
        end
      end
    end
  end
end
```

> Note: the exact bundle path and JS template above are best-guess starting points. When you run the smoke test in Task 12 and it fails, inspect a real working request — search the dummy app's `app/controllers` or `spec/dummy/spec/requests/` for a working server-render call and copy the actual path and js_code shape. Adjust this file and re-run.

- [ ] **Step 3: Commit**

```bash
git add react_on_rails_pro/scripts/load/lib/scenarios/base.rb \
        react_on_rails_pro/scripts/load/lib/scenarios/standard_render.rb
git commit -m "feat(pro): renderer harness — scenario base + standard_render"
```

---

## Task 6: StreamingRender scenario

**Files:**

- Create: `react_on_rails_pro/scripts/load/lib/scenarios/streaming_render.rb`

- [ ] **Step 1: Implement**

```ruby
# frozen_string_literal: true

require_relative "base"

module RendererHarness
  module Scenarios
    class StreamingRender < Base
      JS_TEMPLATE = <<~JS
        (function(){
          var props = %<props>s;
          return ReactOnRails.serverRenderReactComponent({
            name: 'StreamableHelloWorld',
            domNodeId: 'StreamableHelloWorld-react-component',
            props: props,
            trace: false,
            renderingReturnsPromises: true
          });
        })()
      JS

      def perform_request
        js = format(JS_TEMPLATE, props: filler_props.to_json)
        measure do
          bytes_in = 0
          status = nil
          stream = ReactOnRailsPro::Request.render_code_as_stream(
            "/bundles/server-bundle.js/render-stream",
            js,
            is_rsc_payload: false
          )
          stream.each do |chunk|
            bytes_in += chunk.bytesize if chunk.respond_to?(:bytesize)
            status ||= stream.respond_to?(:status) ? stream.status : nil
          end
          { http_status: status, bytes_in: bytes_in, bytes_out: js.bytesize }
        end
      end
    end
  end
end
```

> Note: as with `standard_render`, the bundle path + JS template are starting points. Inspect `spec/dummy/spec/requests/` for the actual streaming render path used by integration tests if this fails.

- [ ] **Step 2: Commit**

```bash
git add react_on_rails_pro/scripts/load/lib/scenarios/streaming_render.rb
git commit -m "feat(pro): renderer harness — streaming_render scenario"
```

---

## Task 7: IncrementalAsync scenario

**Files:**

- Create: `react_on_rails_pro/scripts/load/lib/scenarios/incremental_async.rb`

- [ ] **Step 1: Implement**

```ruby
# frozen_string_literal: true

require_relative "base"

module RendererHarness
  module Scenarios
    class IncrementalAsync < Base
      JS_TEMPLATE = <<~JS
        (function(){
          var props = %<props>s;
          return ReactOnRails.serverRenderReactComponent({
            name: 'AsyncPropsComponent',
            domNodeId: 'AsyncPropsComponent-react-component',
            props: props,
            trace: false,
            renderingReturnsPromises: true
          });
        })()
      JS

      def perform_request
        js = format(JS_TEMPLATE, props: filler_props.to_json)
        increments = config.increments
        measure do
          bytes_in = 0
          status = nil

          stream = ReactOnRailsPro::Request.render_code_with_incremental_updates(
            "/bundles/server-bundle.js/render-incremental",
            js,
            async_props_block: lambda { |emit|
              increments.times do |i|
                emit.call("chunk_#{i}", { i: i, payload: filler_props })
              end
            }
          )

          stream.each do |chunk|
            bytes_in += chunk.bytesize if chunk.respond_to?(:bytesize)
            status ||= stream.respond_to?(:status) ? stream.status : nil
          end
          { http_status: status, bytes_in: bytes_in, bytes_out: js.bytesize }
        end
      end
    end
  end
end
```

> Note: incremental_async ties to the `async_props_block` interface in `request.rb:render_code_with_incremental_updates`. The `emit` lambda signature must match what the live code expects — verify by reading `react_on_rails_pro/lib/react_on_rails_pro/async_props_emitter.rb` and `request.rb` lines 76–120 before running. Adjust the lambda body to match the real signature (it may be `emit.call(key, value)` or `emit.call(component_name:, props:)` depending on the branch).

- [ ] **Step 2: Commit**

```bash
git add react_on_rails_pro/scripts/load/lib/scenarios/incremental_async.rb
git commit -m "feat(pro): renderer harness — incremental_async scenario"
```

---

## Task 8: Runner (concurrency driver)

**Files:**

- Create: `react_on_rails_pro/scripts/load/lib/runner.rb`

- [ ] **Step 1: Implement**

```ruby
# frozen_string_literal: true

module RendererHarness
  class Runner
    attr_reader :results

    def initialize(scenario:, config:)
      @scenario = scenario
      @config = config
      @results = []
      @results_mutex = Mutex.new
    end

    # Returns elapsed seconds.
    def run
      start = monotonic
      threads = build_threads
      threads.each(&:join)
      monotonic - start
    end

    private

    def build_threads
      if @config.requests
        run_by_count
      else
        run_by_duration
      end
    end

    def run_by_count
      remaining = @config.requests
      remaining_mutex = Mutex.new
      Array.new(@config.concurrency) do
        Thread.new do
          @scenario.warmup(@config.warmup) if @config.warmup.positive?
          loop do
            claimed = remaining_mutex.synchronize do
              break nil if remaining <= 0

              remaining -= 1
              true
            end
            break unless claimed

            record(@scenario.perform_request)
          end
        end
      end
    end

    def run_by_duration
      deadline = monotonic + @config.duration
      Array.new(@config.concurrency) do
        Thread.new do
          @scenario.warmup(@config.warmup) if @config.warmup.positive?
          while monotonic < deadline
            record(@scenario.perform_request)
          end
        end
      end
    end

    def record(result)
      @results_mutex.synchronize { @results << result }
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
```

- [ ] **Step 2: Commit**

```bash
git add react_on_rails_pro/scripts/load/lib/runner.rb
git commit -m "feat(pro): renderer harness — concurrency runner"
```

---

## Task 9: Add transport env-var constants to gem

**Files:**

- Modify: `react_on_rails_pro/lib/react_on_rails_pro/constants.rb`

- [ ] **Step 1: Edit constants.rb**

Open `react_on_rails_pro/lib/react_on_rails_pro/constants.rb` and add at the end of the module body:

```ruby
  # Env var used by the renderer load harness (and future async-http branch)
  # to record which transport is active. No behavior switching here.
  RENDERER_TRANSPORT_ENV = "REACT_ON_RAILS_RENDERER_TRANSPORT"
  DEFAULT_RENDERER_TRANSPORT = "httpx"
```

Final file should look like:

```ruby
# frozen_string_literal: true

module ReactOnRailsPro
  # Status code 400 indicates the renderer rejected the request payload or encountered an unhandled render error.
  STATUS_BAD_REQUEST = 400
  # Status code 410 means to resend the request with the updated bundle.
  STATUS_SEND_BUNDLE = 410
  # Status code 412 means protocol versions are incompatible between the server and the renderer.
  STATUS_INCOMPATIBLE = 412

  # Env var used by the renderer load harness (and future async-http branch)
  # to record which transport is active. No behavior switching here.
  RENDERER_TRANSPORT_ENV = "REACT_ON_RAILS_RENDERER_TRANSPORT"
  DEFAULT_RENDERER_TRANSPORT = "httpx"
end
```

- [ ] **Step 2: Run RuboCop on the file**

Run: `cd react_on_rails_pro && bundle exec rubocop lib/react_on_rails_pro/constants.rb`
Expected: no offenses

- [ ] **Step 3: Run existing constants-related tests to ensure nothing broke**

Run: `cd react_on_rails_pro && bundle exec rspec spec/react_on_rails_pro/ --fail-fast`
Expected: all pass

- [ ] **Step 4: Commit**

```bash
git add react_on_rails_pro/lib/react_on_rails_pro/constants.rb
git commit -m "chore(pro): add RENDERER_TRANSPORT_ENV constant for load harness"
```

---

## Task 10: Harness orchestrator

**Files:**

- Create: `react_on_rails_pro/scripts/load/lib/harness.rb`

- [ ] **Step 1: Implement**

```ruby
# frozen_string_literal: true

require "fileutils"
require "time"
require_relative "config"
require_relative "request_result"
require_relative "metrics"
require_relative "memory_sampler"
require_relative "runner"
require_relative "reporters/json_reporter"
require_relative "reporters/csv_reporter"
require_relative "reporters/terminal_reporter"
require_relative "scenarios/standard_render"
require_relative "scenarios/streaming_render"
require_relative "scenarios/incremental_async"

module RendererHarness
  class Harness
    SCENARIO_REGISTRY = {
      "standard_render" => Scenarios::StandardRender,
      "streaming_render" => Scenarios::StreamingRender,
      "incremental_async" => Scenarios::IncrementalAsync
    }.freeze

    def initialize(config)
      @config = config
      @output_dir = config.output_dir || default_output_dir
    end

    def run
      FileUtils.mkdir_p(@output_dir)
      scenario_class = SCENARIO_REGISTRY.fetch(@config.scenario)
      scenario = scenario_class.new(@config)

      sampler = MemorySampler.new(pids: { rails: Process.pid, renderer: @config.renderer_pid })
      sampler.start_background(interval_seconds: @config.mem_interval)

      runner = Runner.new(scenario: scenario, config: @config)
      elapsed = runner.run

      sampler.stop_background
      scenario.cleanup

      summary = build_summary(runner.results, sampler.rows, elapsed)
      write_outputs(summary, runner.results, sampler.rows)
      Reporters::TerminalReporter.print($stdout, summary)
      summary
    end

    private

    def build_summary(results, mem_rows, elapsed)
      lat = Metrics.summarize_latencies(results)
      rails_series = mem_rows.map { |r| [r[:t_seconds].to_f, r[:rails_rss_kb].to_f] }.reject { |_, v| v.zero? }
      renderer_series = mem_rows.map { |r| [r[:t_seconds].to_f, (r[:renderer_rss_kb] || 0).to_f] }.reject { |_, v| v.zero? }

      {
        scenario: @config.scenario,
        transport: ENV.fetch(ReactOnRailsPro::RENDERER_TRANSPORT_ENV, ReactOnRailsPro::DEFAULT_RENDERER_TRANSPORT),
        concurrency: @config.concurrency,
        mix: @config.mix,
        warmup: @config.warmup,
        elapsed_seconds: elapsed,
        ruby_version: RUBY_VERSION,
        hostname: Socket.gethostname,
        requests: {
          count: lat[:count],
          failures: lat[:failures],
          rps: Metrics.rps(count: lat[:count], elapsed_seconds: elapsed)
        },
        latency_ms: lat.slice(:p50, :p90, :p95, :p99, :p99_9, :max, :mean),
        memory: {
          rails_slope_mb_per_min: Metrics.slope_mb_per_min(rails_series),
          renderer_slope_mb_per_min: renderer_series.empty? ? nil : Metrics.slope_mb_per_min(renderer_series)
        },
        output_dir: @output_dir
      }
    end

    def write_outputs(summary, results, mem_rows)
      Reporters::JsonReporter.write(File.join(@output_dir, "summary.json"), summary)
      Reporters::CsvReporter.write_latency(File.join(@output_dir, "latency.csv"), results)
      Reporters::CsvReporter.write_memory(File.join(@output_dir, "memory.csv"), mem_rows)
    end

    def default_output_dir
      ts = Time.now.utc.strftime("%Y-%m-%dT%H-%M-%SZ")
      File.join("tmp", "load-tests", ts)
    end
  end
end
```

Also `require "socket"` at the top (add it after `require "time"`).

- [ ] **Step 2: Commit**

```bash
git add react_on_rails_pro/scripts/load/lib/harness.rb
git commit -m "feat(pro): renderer harness — orchestrator"
```

---

## Task 11: CLI entry + bin wrapper

**Files:**

- Create: `react_on_rails_pro/scripts/load/renderer_harness.rb`
- Create: `react_on_rails_pro/spec/dummy/bin/renderer-harness`

- [ ] **Step 1: Implement CLI entry `scripts/load/renderer_harness.rb`**

```ruby
# frozen_string_literal: true

# Invoked via:
#   cd react_on_rails_pro/spec/dummy
#   bin/renderer-harness [options]
# which runs `bin/rails runner` against this file.

$LOAD_PATH.unshift(File.expand_path("lib", __dir__))

require "config"
require "harness"

config = RendererHarness::Config.parse(ARGV)
summary = RendererHarness::Harness.new(config).run
exit(summary[:requests][:failures].zero? ? 0 : 1)
```

- [ ] **Step 2: Implement bin wrapper `spec/dummy/bin/renderer-harness`**

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
exec bundle exec bin/rails runner ../scripts/load/renderer_harness.rb "$@"
```

- [ ] **Step 3: Make the wrapper executable**

Run: `chmod +x react_on_rails_pro/spec/dummy/bin/renderer-harness`

- [ ] **Step 4: Commit**

```bash
git add react_on_rails_pro/scripts/load/renderer_harness.rb \
        react_on_rails_pro/spec/dummy/bin/renderer-harness
git commit -m "feat(pro): renderer harness — CLI entry + bin wrapper"
```

---

## Task 12: README

**Files:**

- Create: `react_on_rails_pro/scripts/load/README.md`

- [ ] **Step 1: Write README**

````markdown
# Renderer Transport Load and Memory Harness

A reproducible Ruby-based load and memory harness for the React on Rails Pro Rails → Node renderer transport. Designed to compare HTTPX vs async-http transports on correctness, latency, throughput, and memory growth.

## Status

This is the **foundation** PR. It ships:

- Three scenarios: `standard_render`, `streaming_render`, `incremental_async`
- Metrics (latency percentiles, RPS, memory slope), output as JSON + CSV + terminal summary
- Smoke mode for quick local + CI validation
- Harness unit tests (no live HTTP)

Deferred to follow-up issues:

- 410 missing-bundle retry scenario
- Stale-connection scenario (renderer restart)
- Early-disconnect / cancel scenario
- Timeout / hung-renderer scenario
- Comparison mode (diff two run dirs, pass/fail on memory slope + p99 deltas)

## Prerequisites

1. Bundled gems for the dummy app (`cd react_on_rails_pro/spec/dummy && bundle install`).
2. Built JS bundles (the dummy app build chain — see the dummy app README and `react_on_rails_pro/CLAUDE.md`).
3. The node renderer running. From `react_on_rails_pro/spec/dummy/`: `pnpm run node-renderer` (default port 3800).
4. A running Rails app is **not** required to run the harness — the harness uses `bin/rails runner`, which boots Rails in-process to use the existing initializer config.

## Running

All commands run from `react_on_rails_pro/spec/dummy/`:

### Smoke (fastest sanity check, ~30s wall clock)

```bash
bin/renderer-harness --smoke
```
````

Runs 10 standard-render requests, concurrency 1, no warmup. Exits 0 on success.

### Standard scenarios

```bash
# Non-streaming render, 1000 requests across 4 threads
bin/renderer-harness --scenario standard_render --requests 1000 --concurrency 4 --warmup 5

# Streaming render, 60s with 4 threads
bin/renderer-harness --scenario streaming_render --duration 60 --concurrency 4

# Incremental async props
bin/renderer-harness --scenario incremental_async --requests 200 --concurrency 4 --increments 10
```

### Tracking the node-renderer process

To include the node-renderer RSS in `memory.csv`, pass its PID:

```bash
RENDERER_PID=$(pgrep -f "node-renderer")
bin/renderer-harness --scenario standard_render --requests 1000 --renderer-pid $RENDERER_PID
```

## Output

Each run writes to `tmp/load-tests/<UTC-timestamp>/` (gitignored):

- `summary.json` — config, env, aggregates, memory slope
- `latency.csv` — per-request samples
- `memory.csv` — time-series of RSS + GC.stat

A summary block prints to the terminal at the end.

## Interpreting Results

- **p99 latency**: tail latency. Sensitive to GC pauses, connection-pool contention, transport bugs.
- **Failure rate**: anything above 0% during steady-state warrants investigation.
- **Memory slope**: linear regression of RSS post-warmup, in MB/min. A small positive slope is expected as caches warm; a sustained slope > a few MB/min over a long run is a leak suspicion.
- **GC.stat live_slots**: grows quickly then plateaus normally. Continued growth is a leak signal.

## Transport selection

The harness reads `REACT_ON_RAILS_RENDERER_TRANSPORT` (default `httpx`) and records it in `summary.json`. This PR does not switch transports — the async-http branch will add an `async_http` value when it merges. To compare:

```bash
# baseline
REACT_ON_RAILS_RENDERER_TRANSPORT=httpx bin/renderer-harness --scenario streaming_render --duration 60

# (after async-http branch is checked out)
REACT_ON_RAILS_RENDERER_TRANSPORT=async_http bin/renderer-harness --scenario streaming_render --duration 60
```

## Caveats

- `ps -o rss=` units are kB on both macOS and Linux but reporting is best-effort; if the process is gone mid-sample, the row is omitted (not zero-filled).
- FD count is not yet collected — planned for follow-up.
- The harness pins to the renderer URL + password from the dummy app initializer (`config/initializers/react_on_rails_pro.rb`). Override `REACT_RENDERER_URL` env var to point elsewhere.

## CI

- Harness unit tests run with the regular Pro gem unit test sweep (`cd react_on_rails_pro && bundle exec rspec spec/load/`).
- Live smoke is opt-in via `RUN_RENDERER_LOAD_SMOKE=1`; it is not wired into any default workflow in this PR.

````

- [ ] **Step 2: Commit**

```bash
git add react_on_rails_pro/scripts/load/README.md
git commit -m "docs(pro): README for renderer load harness"
````

---

## Task 13: End-to-end smoke verification + fixes

**Files:**

- Verify: all created files
- Likely modify: `scripts/load/lib/scenarios/*` (paths / payloads need to match real dummy app)

- [ ] **Step 1: Build JS bundles and start node renderer**

Run in one terminal:

```bash
cd react_on_rails_pro/spec/dummy
pnpm run node-renderer
```

Expected: renderer listens on port 3800 (look for "Listening on port 3800" in output).

- [ ] **Step 2: In another terminal, run all harness unit tests**

Run:

```bash
cd react_on_rails_pro && bundle exec rspec spec/load/
```

Expected: all pass.

- [ ] **Step 3: Run smoke mode**

Run:

```bash
cd react_on_rails_pro/spec/dummy
bin/renderer-harness --smoke
```

Expected: exit 0, summary block printed, no failures, `tmp/load-tests/<timestamp>/{summary.json,latency.csv,memory.csv}` created.

- [ ] **Step 4: If smoke fails, diagnose**

The most likely failure modes:

1. **Bundle path is wrong** — `render_code` path argument needs to match what the dummy app uses. Look at `react_on_rails_pro/spec/dummy/spec/requests/` and `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_pool/node_rendering_pool.rb` for the canonical pattern, then update `scenarios/standard_render.rb`.
2. **JS template doesn't match what the renderer expects** — read `react_on_rails_pro/lib/react_on_rails_pro/server_rendering_js_code.rb` for how Rails generates the actual JS, then mirror it (simplified) in the scenario.
3. **Component name doesn't exist** — `HelloWorld` is the convention; if absent, pick any registered component from the dummy app's `client/app/packs/server-bundle.js` registration.
4. **Auth failure** — should not happen since `bin/rails runner` loads the initializer with `renderer_password = "myPassword1"`.

Edit the scenario file, rerun smoke, and iterate until it passes. Each iteration is one commit:

```bash
git add react_on_rails_pro/scripts/load/lib/scenarios/standard_render.rb
git commit -m "fix(pro): harness — correct standard_render path/template for dummy app"
```

- [ ] **Step 5: Run each scenario at small scale**

```bash
bin/renderer-harness --scenario standard_render --requests 100 --concurrency 4
bin/renderer-harness --scenario streaming_render --requests 50 --concurrency 4
bin/renderer-harness --scenario incremental_async --requests 30 --concurrency 4 --increments 5
```

Expected: each exits 0 (or with non-zero only if there are genuine failures), and produces non-empty output files. If any scenario fails, fix and commit as above.

- [ ] **Step 6: Run RuboCop on all new files**

Run:

```bash
cd react_on_rails_pro && bundle exec rubocop scripts/load/ spec/load/
```

Expected: no offenses. Fix any reported violations and re-run.

- [ ] **Step 7: Run the full Pro unit test suite one more time**

Run:

```bash
cd react_on_rails_pro && bundle exec rspec spec/react_on_rails_pro/ spec/load/
```

Expected: all pass — confirms the new constant in `constants.rb` and the spec_helper sharing didn't break anything.

- [ ] **Step 8: Final commit if any fixes were made**

```bash
git add -A
git commit -m "fix(pro): harness — final adjustments after smoke verification"
```

---

## Self-Review

**Spec coverage:** every section of the design spec maps to at least one task — scaffolding (T1), metrics (T2), memory sampler (T3), reporters (T4), three scenarios (T5–T7), runner concurrency (T8), gem constants (T9), orchestrator + transport env read (T10), CLI + bin wrapper (T11), README + caveats + planned items (T12), smoke verification + RuboCop + full test sweep (T13).

**Placeholder scan:** no TBD / TODO / "add appropriate error handling" remain. Two "Note" callouts in T5/T6/T7 acknowledge that the exact dummy-app bundle paths and JS templates may need adjustment after the first smoke run — these are realistic implementation notes, not placeholders; T13 step 4 explicitly handles iterating on them.

**Type consistency:** `RequestResult` field set defined in T1 (`latency_ms, bytes_in, bytes_out, ok, error, http_status, scenario, thread_id, t_started_ms`) is used consistently — `Metrics.summarize_latencies` (T2) reads `latency_ms` and `ok`; `CsvReporter::LATENCY_HEADERS` (T4) matches the struct fields exactly; `Scenarios::Base#measure` (T5) sets them all by name; `Runner#record` (T8) and `Harness#run` (T10) just pass them through. The `Config` field set defined in T1 is read by `Runner`, `Harness`, and `Scenarios::Base#filler_props` — `mix`, `increments`, `concurrency`, `warmup`, `requests`, `duration`, `mem_interval`, `renderer_pid`, `output_dir`, `scenario` are all consistent.
