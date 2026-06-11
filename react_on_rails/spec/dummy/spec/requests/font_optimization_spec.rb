# frozen_string_literal: true

require "rails_helper"

# Integration coverage for ReactOnRails::FontHelper#react_on_rails_font_face wired
# into a dummy view via content_for(:head). Asserts the emitted markup lands in the
# rendered document <head> (the non-streaming react_component_hash head-injection
# path that this helper rides on).
describe "Font optimization helper" do
  before { get "/font_optimization_example" }

  it "renders successfully" do
    expect(response).to have_http_status(:ok)
  end

  it "emits a font preload link in the head" do
    head = Nokogiri::HTML(response.body).at_css("head")
    link = head.at_css('link[rel="preload"][as="font"]')
    expect(link).not_to be_nil
    expect(link["href"]).to eq("/fonts/inter-latin-400-normal.woff2")
    expect(link["type"]).to eq("font/woff2")
    expect(link["crossorigin"]).to eq("anonymous")
  end

  it "emits an @font-face with font-display: swap" do
    expect(response.body).to include('font-family: "Inter";')
    expect(response.body).to include("font-display: swap;")
    expect(response.body).to include('src: url("/fonts/inter-latin-400-normal.woff2") format("woff2");')
  end

  it "emits a metric-matched size-adjust fallback face" do
    expect(response.body).to include('font-family: "Inter Fallback";')
    expect(response.body).to include("size-adjust: 107.12%;")
    expect(response.body).to include("ascent-override: 90.44%;")
    expect(response.body).to include("descent-override: 22.52%;")
    expect(response.body).to include("line-gap-override: 0.0%;")
  end
end
