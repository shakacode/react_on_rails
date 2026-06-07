# frozen_string_literal: true

require "rails_helper"

# Integration coverage for the `/posts_page` benchmark route (issue #3602).
#
# `/posts_page` renders DB records synchronously (non-streaming), so when the
# `posts` table was missing in the Pro benchmark suite it surfaced as a hard 500
# on every request. (The streaming RSC posts routes mask that class of failure
# because their HTTP 200 status line is flushed before the body errors.)
#
# These examples do not reproduce the missing-table case itself — the `before`
# block loads the schema (see below), so the table is always present here. The
# missing-table 500 is prevented upstream by seeding the benchmark DB before the
# server starts (.github/workflows/benchmark.yml). What these examples guard is
# the layer above that: with the table in place the route must server-render
# seeded posts and return 200, and an empty table must return 200 "No posts
# found" rather than 500.
#
# Requires the Pro node renderer to be running, like the other server-rendering
# request specs: the page is rendered with `prerender: true`.
RSpec.describe "Posts page", :server_rendering do
  before do
    # The suite intentionally leaves `maintain_test_schema!` disabled, so make
    # this DB-backed spec self-sufficient: load the schema if it is not present
    # yet. Check every table the examples touch (not just `posts`) so a partial
    # schema can't slip past the guard.
    unless %i[users posts comments].all? { |t| ActiveRecord::Base.connection.table_exists?(t) }
      ActiveRecord::Schema.verbose = false
      load Rails.root.join("db/schema.rb")
    end

    Comment.delete_all
    Post.delete_all
    User.delete_all
  end

  let(:seeded_posts) do
    Array.new(2) do |i|
      user = User.create!(name: "User #{i + 1}", email: "user-#{i + 1}@example.com")
      post = user.posts.create!(title: "Sentinel Post #{i + 1}", body: "Body of sentinel post #{i + 1}.")
      post.comments.create!(user: user, body: "Comment on sentinel post #{i + 1}.")
      post
    end
  end

  after do
    Comment.delete_all
    Post.delete_all
    User.delete_all
  end

  it "server-renders the seeded posts and returns 200" do
    seeded_posts

    get "/posts_page"

    expect(response).to have_http_status(:ok)

    # Parse for the heading so we assert "Posts Page" renders specifically in an
    # <h1> (the page chrome), not just anywhere in the body. The seeded titles
    # below are plain-text content, so a raw substring match is sufficient there.
    html = Nokogiri::HTML(response.body)
    expect(html.css("h1").map(&:text)).to include("Posts Page")
    expect(response.body).to include("Sentinel Post 1")
    expect(response.body).to include("Sentinel Post 2")
  end

  it "only loads comments and users for the requested post count" do
    seeded_posts

    sql_events = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
      next if payload[:name].in?(%w[SCHEMA TRANSACTION CACHE])

      sql_events << payload
    end

    begin
      get "/posts_page", params: { posts_count: 1 }
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    expect(response).to have_http_status(:ok)
    # The controller orders by the first post id per user before applying the
    # SQL limit, so this guards the deterministic post selection explicitly.
    expect(response.body).to include(seeded_posts.first.title)
    expect(response.body).not_to include(seeded_posts.second.title)
    comments_queries = sql_events.select { |payload| payload[:name] == "Comment Load" }
    users_queries = sql_events.select { |payload| payload[:name] == "User Load" }
    # Rails names AR load notifications by model, so model names are more stable
    # than matching SQL text across adapters.
    # Exact counts guard the batching contract; extra loads would reintroduce
    # the overfetching/N+1 behavior this benchmark route is meant to catch.
    expect(comments_queries.size).to eq(1), "expected one batched comments load for seeded commented posts"
    expect(users_queries.size).to eq(1), "expected one batched users load for seeded comment authors"
  end

  it "returns an empty page when posts_count is zero" do
    seeded_posts

    get "/posts_page", params: { posts_count: 0 }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No posts found")
    expect(response.body).not_to include("Sentinel Post 1")
    expect(response.body).not_to include("Sentinel Post 2")
  end

  it "uses the default post count for invalid posts_count params" do
    seeded_posts

    get "/posts_page", params: { posts_count: "invalid" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Sentinel Post 1")
    expect(response.body).to include("Sentinel Post 2")
  end

  it "clamps negative posts_count params to an empty page" do
    seeded_posts

    get "/posts_page", params: { posts_count: -5 }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No posts found")
    expect(response.body).not_to include("Sentinel Post 1")
    expect(response.body).not_to include("Sentinel Post 2")
  end

  it "returns 200 (not 500) when there are no posts to render" do
    Comment.delete_all
    Post.delete_all
    User.delete_all

    get "/posts_page"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No posts found")
  end

  it "uses the default artificial_delay for blank and invalid params" do
    expect(parsed_posts_page_artificial_delay(nil)).to eq(0)
    expect(parsed_posts_page_artificial_delay("")).to eq(0)
    expect(parsed_posts_page_artificial_delay("invalid")).to eq(0)
  end

  it "clamps artificial_delay params without sleeping in the request spec" do
    expect(parsed_posts_page_artificial_delay(-1)).to eq(0)
    expect(parsed_posts_page_artificial_delay(1)).to eq(1)
    expect(parsed_posts_page_artificial_delay(99_999)).to eq(10_000)
  end

  def parsed_posts_page_artificial_delay(value)
    controller = PagesController.new
    allow(controller).to receive(:params).and_return(ActionController::Parameters.new(artificial_delay: value))

    controller.__send__(:posts_page_artificial_delay)
  end
end
