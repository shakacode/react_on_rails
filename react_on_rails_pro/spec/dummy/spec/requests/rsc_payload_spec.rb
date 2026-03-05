# frozen_string_literal: true

require "rails_helper"

describe "RSC payload endpoint" do
  around do |example|
    original_annotation_setting = ActionView::Base.annotate_rendered_view_with_filenames

    ActionView::Base.annotate_rendered_view_with_filenames = true

    example.run
  ensure
    ActionView::Base.annotate_rendered_view_with_filenames = original_annotation_setting
  end

  it "returns parseable NDJSON when view annotation comments are enabled" do
    get "/rsc_payload/RscEchoProps", params: { props: { message: "hello" }.to_json }

    expect(response).to have_http_status(:ok)

    parsed_chunks = response.body.each_line.filter_map do |line|
      stripped_line = line.strip
      next if stripped_line.empty?

      JSON.parse(stripped_line)
    end

    expect(parsed_chunks).not_to be_empty
    expect(parsed_chunks).to all(include("html"))
  end
end
