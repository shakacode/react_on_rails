# frozen_string_literal: true

# Renders a benchmark suite's results as a Markdown section: a pipe table whose
# tracked-measure cells (RPS, p50) are bolded and tagged 🔴 (regression) / 🟢
# (improvement) when the value crossed its t-test prediction interval in either
# direction, driven by a BencherReport. Non-tracked columns (p90, Status) are
# shown but never highlighted. Pure string building — no I/O.
class BenchmarkTable
  REGRESSION = "🔴"
  IMPROVEMENT = "🟢"

  # Display-order columns. A :measure + :direction makes the column highlightable
  # and MUST match the tracked measure/side in track_benchmarks.rb THRESHOLDS
  # (rps: higher-is-better/:lower; p50_latency and failed_pct: lower-is-better/:upper).
  # Every THRESHOLDS measure has a highlightable column here (pinned both directions by
  # track_benchmarks_spec.rb) so an alert on any tracked measure is visible in the
  # table. Columns without :measure (p90, Status) are shown but never highlighted.
  COLUMNS = [
    { header: "Benchmark", field: "name" },
    { header: "RPS", field: "rps", measure: "rps", direction: :lower },
    { header: "p50(ms)", field: "p50", measure: "p50_latency", direction: :upper },
    { header: "p90(ms)", field: "p90" },
    { header: "Fail%", field: "failed_pct", measure: "failed_pct", direction: :upper },
    { header: "Status", field: "status" }
  ].freeze

  LEGEND = "#{REGRESSION} significant regression · #{IMPROVEMENT} significant " \
           "improvement (vs baseline; tracked measures only)".freeze

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
    value = row[col[:field]]
    text = render_value(value)
    # Only tracked, numeric cells can be highlighted: a non-tracked column has no
    # :measure, and a missing/failed value (nil) has nothing meaningful to flag.
    return text unless col[:measure] && @report && value.is_a?(Numeric)

    case @report.significance(row["name"], col[:measure], col[:direction])
    when :regression then "**#{text}** #{REGRESSION}"
    when :improvement then "**#{text}** #{IMPROVEMENT}"
    else text
    end
  end

  def render_value(value)
    return "—" if value.nil?

    # Escape the Markdown metacharacters that affect inline rendering in a table cell,
    # in a single pass (which avoids double-escaping): the pipe (breaks the column
    # structure), the backslash (the escape char itself — also satisfies static
    # analysis), and *, _, ` (emphasis/code spans — a route or test name with
    # underscores/asterisks/backticks would otherwise render as Markdown). Cell values
    # are controlled CI output (route paths, test names, status strings like
    # "200=900,5xx=10"), so this is rendering robustness, not untrusted-input sanitizing.
    value.to_s.gsub(/[\\`*_|]/) { |char| "\\#{char}" }
  end
end
