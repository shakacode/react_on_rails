shared_examples "bootstrap" do
  it "appends path configurations to assets.rb" do
    expected = <<-EXPECTED.strip_heredoc
      # Add client/assets/ folders to asset pipeline's search path.
      # If you do not want to move existing images and fonts from your Rails app
      # you could also consider creating symlinks there that point to the original
      # rails directories. In that case, you would not add these paths here.
      Rails.application.config.assets.paths << Rails.root.join("client", "assets", "stylesheets")
      Rails.application.config.assets.paths << Rails.root.join("client", "assets", "images")
      Rails.application.config.assets.paths << Rails.root.join("client", "assets", "fonts")

      Rails.application.config.assets.precompile += %w( generated/server-bundle.js )
    EXPECTED
    assert_file("config/initializers/assets.rb") { |contents| assert_match(expected, contents) }
  end

  it "removes incompatible requires in application.css.scss" do
    assert_file("app/assets/stylesheets/application.css.scss") do |contents|
      refute_match("*= require_tree .", contents)
      refute_match("*= require_self", contents)
    end
  end

  it "copies bootstrap files" do
    %w(app/assets/stylesheets/_bootstrap-custom.scss
       app/assets/stylesheets/application.css.scss
       client/assets/stylesheets/_post-bootstrap.scss
       client/assets/stylesheets/_pre-bootstrap.scss
       client/assets/stylesheets/_react-on-rails-sass-helper.scss
       client/bootstrap-sass.config.js).each { |file| assert_file(file) }
  end

  it "adds bootstrap_sprockets to the Gemfile" do
    assert_file("Gemfile") do |contents|
      assert_match(/gem 'bootstrap-sass'/, contents)
    end
  end
end
