# frozen_string_literal: true

require "rails_helper"

# Integration coverage for the streaming RSC posts benchmark route (issue #3625).
#
# The route can flush HTTP 200 before the body finishes rendering, so this spec
# asserts user-visible streamed post content rather than status alone.
# The HTTP variant still fetches from a hard-coded local server URL; this covers
# the Redis route, which can be exercised in request specs with a Redis service.
RSpec.describe "RSC posts page", :server_rendering do
  before do
    # Match posts_page_spec.rb: maintain_test_schema! is disabled in this suite,
    # so DB-backed request specs must load the schema when needed.
    unless %i[users posts comments].all? { |t| ActiveRecord::Base.connection.table_exists?(t) }
      ActiveRecord::Schema.verbose = false
      load Rails.root.join("db/schema.rb")
    end

    Comment.delete_all
    Post.delete_all
    User.delete_all

    2.times do |i|
      user = User.create!(name: "User #{i + 1}", email: "user-#{i + 1}@example.com")
      post = user.posts.create!(title: "Sentinel Post #{i + 1}", body: "Body of sentinel post #{i + 1}.")
      post.comments.create!(user:, body: "Comment on sentinel post #{i + 1}.")
    end
  end

  after do
    Comment.delete_all
    Post.delete_all
    User.delete_all
  end

  it "streams seeded posts over Redis and returns 200" do
    get "/rsc_posts_page_over_redis"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("RSC Posts Page")
    expect(response.body).to include("Sentinel Post 1")
    expect(response.body).to include("Sentinel Post 2")
    expect(response.body).not_to include("Error in RSC stream")
  end
end
