# frozen_string_literal: true

# Renders a benchmark suite's results as a Markdown section: a pipe table whose tracked
# metric cells (RPS, p50, p90) show the value, a ▲/▼ delta vs the Bencher baseline, and
# the baseline in parentheses. A value that crossed its t-test prediction interval is
# bolded with the arrow replaced by 🔴 (regression) / 🟢 (improvement), driven by a
# BencherReport. The benchmark name links to that benchmark's perf plot when the report
# exposes one. Pure string building — no I/O.
class BenchmarkTable
  REGRESSION = "🔴"
  IMPROVEMENT = "🟢"
  UNCONFIRMED = "⚠️"
  UP = "▲"
  DOWN = "▼"

  # Display-order columns. A :measure makes the cell carry a baseline delta; a :measure
  # WITH a :direction also makes it highlightable and MUST match the tracked measure/side
  # in track_benchmarks.rb THRESHOLDS (rps: higher-is-better/:lower; p50_latency:
  # lower-is-better/:upper). Every THRESHOLDS-tracked-AND-displayed measure has a
  # highlightable column here (pinned by track_benchmarks_spec.rb) so an alert on a
  # displayed measure is visible. p90_latency has a baseline column but no :direction:
  # it is sent to Bencher boundary-less (no threshold), so it shows a delta if a baseline
  # exists but is never flagged significant. failed_pct stays tracked in THRESHOLDS for
  # alerting but is intentionally NOT a column (redundant with Status — issue #3601 item 4).
  COLUMNS = [
    { header: "Benchmark", field: "name" },
    { header: "RPS", field: "rps", measure: "rps", direction: :lower },
    { header: "p50(ms)", field: "p50", measure: "p50_latency", direction: :upper },
    { header: "p90(ms)", field: "p90", measure: "p90_latency" },
    { header: "Status", field: "status" }
  ].freeze

  # "(tracked measures)" qualifies the 🔴/🟢 significance flags, not the baseline: only
  # tracked measures (rps, p50) are flagged significant, but ANY measure with a baseline
  # (including the untracked p90) shows a ▲/▼ delta and an "(n)" baseline.
  LEGEND = "#{UP}/#{DOWN} non-zero change vs baseline · 0.0% exact/near-zero match · " \
           "#{REGRESSION} significant regression · " \
           "#{IMPROVEMENT} significant improvement (tracked measures) · " \
           "#{UNCONFIRMED} crossed threshold but base/head samples overlap (unconfirmed) · " \
           "(n) = baseline".freeze

  EMPTY = "_No benchmark results._"

  def initialize(title:, rows:, report:)
    @title = title
    @rows = rows
    @report = report
  end

  def to_markdown
    body = @rows.empty? ? EMPTY : table
    <<~MARKDOWN
      ### #{@title}

      #{body}
    MARKDOWN
  end

  private

  def table
    [header_row, divider_row, *@rows.map { |row| data_row(row) }, "", LEGEND].join("\n")
  end

  def header_row
    "| #{COLUMNS.map { |col| col[:header] }.join(' | ')} |"
  end

  def divider_row
    "| #{COLUMNS.map { '---' }.join(' | ')} |"
  end

  def data_row(row)
    "| #{COLUMNS.map { |col| cell(row, col) }.join(' | ')} |"
  end

  def cell(row, col)
    return name_cell(row) if col[:field] == "name"

    value = row[col[:field]]
    # Only tracked, numeric cells get a delta: a non-tracked column has no :measure, and a
    # missing/failed value (nil or a "FAILED"/"MISSING" token) has no baseline to compare.
    return render_value(value) unless col[:measure] && @report && value.is_a?(Numeric)

    metric_cell(row["name"], col, value)
  end

  # The benchmark name, linked to its Bencher perf plot when the report exposes a URL.
  # The link text is render_value-escaped, which now includes [] (see render_value), so a
  # name with a bracket can't prematurely close the [text](url) link — defense in depth on
  # top of names being controlled CI output (route paths, test names).
  def name_cell(row)
    name = row["name"]
    text = render_value(name)
    url = @report&.perf_url(name)
    url ? "[#{text}](#{url})" : text
  end

  # value + ▲/▼ delta + (baseline), with the arrow swapped for 🔴/🟢 and the value bolded
  # when the measure crossed its boundary. An :unconfirmed verdict (crossed the boundary
  # but the change did not reproduce across repeated samples) renders ⚠️ plus the plain
  # arrow, unbolded — visible but not crying wolf. No baseline (new benchmark /
  # boundary-less p90) or zero baseline (no meaningful percent) → just the value.
  def metric_cell(name, col, value)
    text = format_number(value).to_s
    baseline = @report.boundary(name, col[:measure])&.baseline
    # No baseline (new benchmark / boundary-less p90), a zero baseline (no meaningful
    # percent, and it would divide by zero) → just the value.
    return text if baseline.nil? || baseline.zero?

    verdict = col[:direction] ? @report.significance(name, col[:measure], col[:direction]) : nil
    value_text = %i[regression improvement].include?(verdict) ? "**#{text}**" : text
    "#{value_text} #{delta(verdict, value, baseline)} (#{format_number(baseline)})"
  end

  # "▲2.3%" / "▼1.4%" for a plain change; "🔴 8.4%" / "🟢 5.0%" for a significant one (the
  # emoji gets a trailing space so it renders clear of the percent); "⚠️ ▲8.4%" for a
  # boundary crossing that did not reproduce across samples. Non-significant
  # rounded-to-zero changes display as plain "0.0%" so equality/tiny noise never gets a
  # misleading arrow, while significant verdicts keep their marker.
  # The percent is the absolute change vs baseline; direction is conveyed by the arrow,
  # or by the emoji plus the column's known better-direction.
  def delta(verdict, value, baseline)
    percent = ((value - baseline) / baseline * 100).abs.round(1)
    return "#{percent}%" if percent.zero? && verdict.nil?

    case verdict
    when :regression then "#{REGRESSION} #{percent}%"
    when :improvement then "#{IMPROVEMENT} #{percent}%"
    when :unconfirmed then "#{UNCONFIRMED} #{value > baseline ? UP : DOWN}#{percent}%"
    else "#{value > baseline ? UP : DOWN}#{percent}%"
    end
  end

  def format_number(number)
    number.round(2)
  end

  def render_value(value)
    return "—" if value.nil?

    # Escape the Markdown metacharacters that affect inline rendering in a table cell,
    # in a single pass (which avoids double-escaping): the pipe (breaks the column
    # structure), the backslash (the escape char itself — also satisfies static
    # analysis), *, _, ` (emphasis/code spans — a route or test name with
    # underscores/asterisks/backticks would otherwise render as Markdown), and [] (so a
    # bracket can't close the [text](url) link wrapping the name — see name_cell). Cell
    # values are controlled CI output (route paths, test names, status strings like
    # "200=900,5xx=10"), so this is rendering robustness, not untrusted-input sanitizing.
    value.to_s.gsub(/[\\`*_|\[\]]/) { |char| "\\#{char}" }
  end
end
