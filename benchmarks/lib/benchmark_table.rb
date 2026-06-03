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
  # (rps: higher-is-better/:lower; p50_latency: lower-is-better/:upper). Columns
  # without them (p90, Status) are shown but never highlighted.
  COLUMNS = [
    { header: "Benchmark", field: "name" },
    { header: "RPS", field: "rps", measure: "rps", direction: :lower },
    { header: "p50(ms)", field: "p50", measure: "p50_latency", direction: :upper },
    { header: "p90(ms)", field: "p90" },
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

    value.to_s.gsub("|", "\\|")
  end
end
