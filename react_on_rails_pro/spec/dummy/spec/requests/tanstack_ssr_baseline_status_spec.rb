# frozen_string_literal: true

# Issue #5125 regression spec: TanStack Router SSR HTTP status codes.
#
# Each test asserts the single correct HTTP outcome for its route type.
# On the baseline (unfixed) code, every non-200 assertion fails — that is the bug.

require "rails_helper"

describe "Issue #5125: TanStack Router SSR HTTP status" do
  # ── Normal routes: 200 with rendered content ──

  it "GET /tanstack_starter returns 200 with home page content" do
    get "/tanstack_starter"
    expect(response).to have_http_status(200)
    expect(response.body).to include("tanstack-starter-home")
    expect(response.headers["Location"]).to be_nil
  end

  it "GET /tanstack_starter/about returns 200 with about page content" do
    get "/tanstack_starter/about"
    expect(response).to have_http_status(200)
    expect(response.body).to include("tanstack-starter-about")
    expect(response.headers["Location"]).to be_nil
  end

  # ── User-defined redirect: 307 with exact Location ──

  it "GET /tanstack_starter/redirect_target returns 307 to /tanstack_starter" do
    get "/tanstack_starter/redirect_target"
    expect(response).to have_http_status(307)
    expect(response.headers["Location"]).to eq("/tanstack_starter")
  end

  # ── User-defined permanent redirect: 301 with exact Location ──

  it "GET /tanstack_starter/permanent_redirect returns 301 to /tanstack_starter/about" do
    get "/tanstack_starter/permanent_redirect"
    expect(response).to have_http_status(301)
    expect(response.headers["Location"]).to eq("/tanstack_starter/about")
  end

  # ── Loader notFound(): 404 with not-found component ──

  it "GET /tanstack_starter/not_found_loader returns 404 with not-found content" do
    get "/tanstack_starter/not_found_loader"
    expect(response).to have_http_status(404)
    expect(response.body).to include("tanstack-starter-not-found")
    expect(response.headers["Location"]).to be_nil
  end

  # ── Unmatched path: 404 with not-found component ──

  it "GET /tanstack_starter/this_does_not_exist returns 404 with not-found content" do
    get "/tanstack_starter/this_does_not_exist"
    expect(response).to have_http_status(404)
    expect(response.body).to include("tanstack-starter-not-found")
    expect(response.headers["Location"]).to be_nil
  end

  # ── Loader error: 302 redirect via rescue_from ──
  #
  # The view sets raise_on_prerender_error: true, so a loader error raises
  # ReactOnRails::PrerenderError. ApplicationController's rescue_from catches
  # it and redirects to server_side_log_throw_raise_invoker_path (302).

  it "GET /tanstack_starter/loader_error returns 302 (rescue_from redirects)" do
    get "/tanstack_starter/loader_error"
    expect(response).to have_http_status(302)
    expect(response.headers["Location"]).to include("server_side_log_throw_raise_invoker")
  end

  # ── Trailing-slash canonicalization: 307 to canonical URL ──
  #
  # TanStack Router's trailingSlash: 'never' (default) triggers a 307 redirect
  # when the URL has a trailing slash. SsrStatusHandler converts it to a real
  # HTTP redirect.

  it "GET /tanstack_starter/ (trailing slash) returns 307 to /tanstack_starter" do
    get "/tanstack_starter/"
    expect(response).to have_http_status(307)
    expect(response.headers["Location"]).to eq("/tanstack_starter")
  end

  # ── Query canonicalization: 307 to percent-encoded canonical URL ──
  #
  # TanStack Router re-encodes query values (commas become %2C).

  it "GET /tanstack_starter?ids=1,2 returns 307 to percent-encoded canonical URL" do
    get "/tanstack_starter?ids=1,2"
    expect(response).to have_http_status(307)
    expect(response.headers["Location"]).to eq("/tanstack_starter?ids=1%2C2")
  end
end
