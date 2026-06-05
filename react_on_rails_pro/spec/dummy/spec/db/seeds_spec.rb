# frozen_string_literal: true

require "rails_helper"

# Unit coverage for `db/seeds.rb`, the layer that actually broke in issue #3602.
#
# The Pro benchmark workflow runs `rails db:prepare` under RAILS_ENV=production,
# where the development/test-only `faker` gem is NOT in the bundle. If seeds.rb
# reintroduces a `Faker::...` call (or otherwise stops populating the tables),
# the production CI run leaves `/posts_page` with no data — exactly the #3602
# failure. These examples reproduce that environment by hiding the `Faker`
# constant while loading the seed file, so such a regression fails here (on every
# Pro dummy spec run) instead of silently in the benchmark suite.
#
# Unlike posts_page_spec.rb this needs no node renderer — it only touches the DB.
RSpec.describe "db/seeds.rb" do
  before do
    # maintain_test_schema! is disabled in this suite (see posts_page_spec.rb), so
    # load the schema if the tables the seeds touch are missing.
    unless %i[users posts comments].all? { |t| ActiveRecord::Base.connection.table_exists?(t) }
      ActiveRecord::Schema.verbose = false
      load Rails.root.join("db/schema.rb")
    end
  end

  after do
    Comment.delete_all
    Post.delete_all
    User.delete_all
  end

  # seeds.rb is `load`ed (not `require`d) in production via db:prepare; do the
  # same here. It clears the tables itself, so each load starts from a clean slate.
  # Its progress `puts` output is captured to keep spec output quiet.
  def load_seeds
    original_stdout = $stdout
    $stdout = StringIO.new
    load Rails.root.join("db/seeds.rb")
  ensure
    $stdout = original_stdout
  end

  it "populates users, posts, and comments without the faker gem" do
    hide_const("Faker")

    expect { load_seeds }.not_to raise_error

    expect(User.count).to be_positive
    expect(Post.count).to be_positive
    expect(Comment.count).to be_positive
  end

  it "produces identical data on every load (deterministic, reproducible benchmarks)" do
    hide_const("Faker")

    load_seeds
    first = { users: User.count, posts: Post.count, comments: Comment.count,
              titles: Post.order(:id).pluck(:title) }

    load_seeds
    second = { users: User.count, posts: Post.count, comments: Comment.count,
               titles: Post.order(:id).pluck(:title) }

    expect(second).to eq(first)
  end
end
