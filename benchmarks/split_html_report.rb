# frozen_string_literal: true

# Splits Bencher HTML report into multiple chunks for PR comments
# No external dependencies - uses only Ruby stdlib

# GitHub PR comment size limit. The documented limit is 65536 characters,
# but in practice larger HTML content works (likely compressed).
# Testing showed 250KB works, 300KB fails. Using 220KB for safety margin.
MAX_COMMENT_SIZE = 220 * 1024
SAFETY_MARGIN = 500
MAX_CHUNK_SIZE = MAX_COMMENT_SIZE - SAFETY_MARGIN

MARKER = "<!-- BENCHER_REPORT -->"

# rubocop:disable Metrics/AbcSize
def split_html_report(html)
  # Find the main data table's tbody content
  # Structure: <h2>...<table>info</table><details>...<table><thead>...</thead><tbody>ROWS</tbody></table></details>

  # Extract header (everything up to and including <tbody>)
  tbody_start = html.index("<tbody>")
  return ["#{MARKER}\n#{html}"] unless tbody_start

  header = html[0..tbody_start + 6] # includes "<tbody>"

  # Extract footer (</tbody></table></details> and anything after)
  tbody_end = html.index("</tbody>")
  return ["#{MARKER}\n#{html}"] unless tbody_end

  footer = html[tbody_end..]

  # Extract all table rows
  tbody_content = html[tbody_start + 7...tbody_end]
  rows = tbody_content.scan(%r{<tr>.*?</tr>}m)

  return ["#{MARKER}\n#{html}"] if rows.empty?

  # Calculate overhead for each chunk
  chunk_overhead = MARKER.bytesize + 1 + header.bytesize + footer.bytesize

  # Group rows into chunks
  chunks = []
  current_rows = []
  current_size = chunk_overhead

  rows.each do |row|
    row_size = row.bytesize

    if current_size + row_size > MAX_CHUNK_SIZE && current_rows.any?
      # Save current chunk
      chunks << build_chunk(header, current_rows, footer)
      current_rows = []
      current_size = chunk_overhead
    end

    current_rows << row
    current_size += row_size
  end

  # Add remaining rows
  chunks << build_chunk(header, current_rows, footer) if current_rows.any?

  chunks
end
# rubocop:enable Metrics/AbcSize

def build_chunk(header, rows, footer)
  "#{MARKER}\n#{header}#{rows.join}#{footer}"
end

# CLI
if __FILE__ == $PROGRAM_NAME
  input_file = ARGV[0]
  output_prefix = ARGV[1] || "chunk"

  unless input_file
    warn "Usage: #{$PROGRAM_NAME} <input.html> [output_prefix]"
    exit 1
  end

  html = File.read(input_file)
  chunks = split_html_report(html)

  chunks.each_with_index do |chunk, i|
    suffix = chunks.length > 1 ? ".#{i + 1}" : ""
    output_file = "#{output_prefix}#{suffix}.html"
    File.write(output_file, chunk)
    puts "Wrote #{output_file} (#{chunk.bytesize} bytes)"
  end
end
