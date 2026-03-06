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
        raise "Non-JSON line in RSC payload response: #{stripped_line.inspect} (#{e.message})"
      end
    end
  end

  def expect_valid_rsc_payload_response
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/x-ndjson")
    expect(response.body).not_to include("<!--")

    expect(parsed_chunks).not_to be_empty
    html_chunk_message =
      "Expected at least one RSC chunk to contain an 'html' key, got: #{parsed_chunks.inspect}"
    expect(parsed_chunks.any? { |chunk| chunk.key?("html") }).to be(true), html_chunk_message
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
    expect(render_annotated_html_inline_template).to include("<!--")

    request_rsc_payload

    expect_valid_rsc_payload_response
  end
end
