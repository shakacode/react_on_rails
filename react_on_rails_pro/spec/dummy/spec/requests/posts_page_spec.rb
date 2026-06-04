# frozen_string_literal: true

require "rails_helper"

# Integration coverage for the `/posts_page` benchmark route (issue #3602).
#
# `/posts_page` is the only synchronous (non-streaming) benchmark route that
# reads from the database, so a missing `posts` table surfaces as a hard 500 on
# every request — which is exactly how it regressed in the Pro benchmark suite.
# (The streaming RSC posts routes mask the same failure because their HTTP 200
# status line is sent before the body errors.) These examples render the page
# with seeded records and assert it returns 200 with the post content, guarding
# against the route silently breaking again.
#
# Requires the Pro node renderer to be running, like the other server-rendering
# request specs: the page is rendered with `prerender: true`.
RSpec.describe "Posts page", :server_rendering do
  before do
    # The suite intentionally leaves `maintain_test_schema!` disabled, so make
    # this DB-backed spec self-sufficient: load the schema if it is not present
    # yet. The table check is cheap and the load only runs on the first example.
    unless ActiveRecord::Base.connection.table_exists?(:posts)
      ActiveRecord::Schema.verbose = false
      load Rails.root.join("db/schema.rb")
    end

    Comment.delete_all
    Post.delete_all
    User.delete_all

    2.times do |i|
      user = User.create!(name: "User #{i + 1}", email: "user-#{i + 1}@example.com")
      post = user.posts.create!(title: "Sentinel Post #{i + 1}", body: "Body of sentinel post #{i + 1}.")
      post.comments.create!(user: user, body: "Comment on sentinel post #{i + 1}.")
    end
  end

  after do
    Comment.delete_all
    Post.delete_all
    User.delete_all
  end

  it "server-renders the seeded posts and returns 200" do
    get "/posts_page"

    expect(response).to have_http_status(:ok)

    html = Nokogiri::HTML(response.body)
    expect(html.css("h1").map(&:text)).to include("Posts Page")
    expect(response.body).to include("Sentinel Post 1")
    expect(response.body).to include("Sentinel Post 2")
  end

  it "returns 200 (not 500) when there are no posts to render" do
    Comment.delete_all
    Post.delete_all
    User.delete_all

    get "/posts_page"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No posts found")
  end
end
