# frozen_string_literal: true

require "rails_helper"

RSpec.describe "RSC payload endpoint" do
  def request_rsc_payload
    get "/rsc_payload/RscEchoProps", params: { props: { message: "hello" }.to_json }
  end

  def parsed_chunks
    response.body.each_line.filter_map do |line|
      stripped_line = line.strip
      next if stripped_line.empty?

      begin
        JSON.parse(stripped_line)
      rescue JSON::ParserError => e
        raise "Rails view annotation leaked into RSC payload response: #{stripped_line.inspect}" \
          if stripped_line.include?("<!--")

        raise "Non-JSON line in RSC payload response: #{stripped_line.inspect} (#{e.message})"
      end
    end
  end

  def expect_valid_rsc_payload_response
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/x-ndjson")

    chunks = parsed_chunks

    expect(chunks).not_to be_empty
    html_chunk_message =
      "Expected at least one RSC chunk to contain an 'html' key, got: #{chunks.inspect}"
    expect(chunks.any? { |chunk| chunk.key?("html") }).to be(true), html_chunk_message
  end

  def render_annotated_html_inline_template
    ApplicationController.render(inline: "<p>hello</p>", type: :erb, layout: false, formats: [:html])
  end

  it "returns parseable NDJSON without view annotation comments" do
    request_rsc_payload
    expect_valid_rsc_payload_response
  end

  it "returns parseable NDJSON when view annotation comments are enabled" do
    allow(ActionView::Base).to receive(:annotate_rendered_view_with_filenames).and_return(true)

    # Rails annotation comment format verified against Rails 7.x.
    # If this assertion fails after a Rails upgrade, check ActionView annotation output.
    annotated = nil
    expect { annotated = render_annotated_html_inline_template }.not_to raise_error
    expect(annotated).to include(
      "<!--"
    ), "Rails annotation comment format may have changed - check ActionView annotation output."

    request_rsc_payload

    expect_valid_rsc_payload_response
  end

  it "returns bad request for malformed props JSON" do
    get "/rsc_payload/RscEchoProps", params: { props: '{"message":' }

    expect(response).to have_http_status(:bad_request)
    expect(response.media_type).to eq("text/plain")
    expect(response.body).to eq("Invalid props JSON")
  end
end
