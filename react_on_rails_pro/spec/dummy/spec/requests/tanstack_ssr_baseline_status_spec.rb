# frozen_string_literal: true

# Issue #5125 regression spec: TanStack Router SSR HTTP status codes.
#
# Each test documents the EXPECTED (correct) HTTP behavior for each route type.
# On the baseline (unfixed) code, the tests that assert non-200 statuses FAIL —
# that is the bug. Once fixed, all tests should pass.

require "rails_helper"

describe "Issue #5125: TanStack Router SSR HTTP status" do
  # ── Normal routes: should return 200 with rendered content ──

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

  # ── User-defined redirect: should return 307 with Location header ──

  it "GET /tanstack_starter/redirect_target returns 307 with Location: /tanstack_starter" do
    get "/tanstack_starter/redirect_target"
    expect(response).to have_http_status(307)
    expect(response.headers["Location"]).to eq("/tanstack_starter")
  end

  # ── User-defined permanent redirect: should return 301 ──

  it "GET /tanstack_starter/permanent_redirect returns 301 with Location: /tanstack_starter/about" do
    get "/tanstack_starter/permanent_redirect"
    expect(response).to have_http_status(301)
    expect(response.headers["Location"]).to eq("/tanstack_starter/about")
  end

  # ── Loader notFound(): should return 404 with not-found component ──

  it "GET /tanstack_starter/not_found_loader returns 404 with not-found content" do
    get "/tanstack_starter/not_found_loader"
    expect(response).to have_http_status(404)
    expect(response.body).to include("tanstack-starter-not-found")
  end

  # ── Unmatched path: should return 404 with not-found component ──

  it "GET /tanstack_starter/this_does_not_exist returns 404 with not-found content" do
    get "/tanstack_starter/this_does_not_exist"
    expect(response).to have_http_status(404)
    expect(response.body).to include("tanstack-starter-not-found")
  end

  # ── Loader error: should return 500 (or be handled by raise_on_prerender_error) ──
  #
  # The view uses raise_on_prerender_error: true, so a loader error raises
  # ReactOnRails::PrerenderError. TanstackStarterController inherits from
  # ApplicationController, whose rescue_from redirects to
  # server_side_log_throw_raise_invoker_path (302). This test documents that
  # behavior — the router itself sets statusCode=500, but the controller
  # rescue_from intercepts before the status reaches the response.

  it "GET /tanstack_starter/loader_error is handled by the controller rescue_from" do
    get "/tanstack_starter/loader_error"
    # ApplicationController's rescue_from catches PrerenderError and redirects.
    # If raise_on_prerender_error were false, the status would be 500.
    expect(response.status).to be_in([302, 500])
  end

  # ── Trailing-slash canonicalization ──
  #
  # TanStack Router's default trailingSlash: 'never' setting causes a 307
  # redirect when the URL has a trailing slash. After the fix, this should
  # either redirect properly (307 + Location) or render the correct page (200).

  it "GET /tanstack_starter/ (trailing slash) returns rendered content or a redirect" do
    get "/tanstack_starter/"
    if response.status == 307 || response.status == 301
      expect(response.headers["Location"]).to be_present
    else
      expect(response).to have_http_status(200)
      expect(response.body).to include("tanstack-starter-home")
    end
  end

  # ── Query canonicalization ──

  it "GET /tanstack_starter?ids=1,2 (non-canonical query) returns content or a redirect" do
    get "/tanstack_starter?ids=1,2"
    if response.status == 307 || response.status == 301
      expect(response.headers["Location"]).to be_present
    else
      expect(response).to have_http_status(200)
      expect(response.body).to include("tanstack-starter-home")
    end
  end
end
