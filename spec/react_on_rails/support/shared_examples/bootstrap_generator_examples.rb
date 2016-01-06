shared_examples "bootstrap:enabled" do
  it "removes incompatible requires in application.scss" do
    assert_file("app/assets/stylesheets/application.scss") do |contents|
      refute_match("*= require_tree .", contents)
      refute_match("*= require_self", contents)
    end
  end

  it "appends bootstrap related contents in application.scss" do
    assert_file("app/assets/stylesheets/application.scss") do |contents|
      assert_match(bootstrap_related_css_contents, contents)
    end
  end

  it "appends bootstrap related js contents in application.js" do
    assert_file("app/assets/javascripts/application.js") do |contents|
      assert_match(bootstrap_related_js_contents, contents)
    end
  end

  it "copies bootstrap files" do
    bootstrap_related_files.each { |file| assert_file(file) }
  end

  it "adds bootstrap_sprockets to the Gemfile" do
    assert_file("Gemfile") do |contents|
      assert_match(/gem 'bootstrap-sass'/, contents)
    end
  end

  it "adds react-bootstrap, bootstrap-sass, bootstrap-sass-loader to the package.json" do
    assert_file("client/package.json") do |contents|
      assert_match(/"react-bootstrap"/, contents)
      assert_match(/"bootstrap-sass"/, contents)
      assert_match(/"bootstrap-sass-loader"/, contents)
    end
  end

  it "adds react-bootstrap to client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx" do
    assert_file("client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx") do |contents|
      assert_match(/'react-bootstrap'/, contents)
      assert_match(/<Input/, contents)
    end
  end
end

shared_examples "bootstrap:disabled" do
  it "doesn't copy bootstrap files" do
    bootstrap_related_files.each { |file| assert_no_file(file) }
  end

  it "doesn't add bootstrap_sprockets to the Gemfile" do
    assert_file("Gemfile") do |contents|
      refute_match(/gem 'bootstrap-sass'/, contents)
    end
  end

  it "doesn't append bootstrap related contents in application.scss" do
    assert_file("app/assets/stylesheets/application.scss") do |contents|
      refute_match(bootstrap_related_css_contents, contents)
    end
  end

  it "doesn't append bootstrap related js contents in application.js" do
    assert_file("app/assets/javascripts/application.js") do |contents|
      refute_match(bootstrap_related_js_contents, contents)
    end
  end

  it "doesn't add react-bootstrap, bootstrap-sass and bootstrap-sass-loader to the Gemfile" do
    assert_file("client/package.json") do |contents|
      refute_match(/"react-bootstrap"/, contents)
      refute_match(/"bootstrap-sass"/, contents)
      refute_match(/"bootstrap-sass-loader"/, contents)
    end
  end

  it "adds react-bootstrap to client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx" do
    assert_file("client/app/bundles/HelloWorld/components/HelloWorldWidget.jsx") do |contents|
      refute_match(/'react-bootstrap'/, contents)
      refute_match(/<Input/, contents)
    end
  end
end

def bootstrap_related_files
  %w(app/assets/stylesheets/_bootstrap-custom.scss
     client/assets/stylesheets/_post-bootstrap.scss
     client/assets/stylesheets/_pre-bootstrap.scss
     client/assets/stylesheets/_react-on-rails-sass-helper.scss
     client/bootstrap-sass.config.js)
end

def bootstrap_related_css_contents
  <<-DATA.strip_heredoc
    // DO NOT REQUIRE TREE! It will interfere with load order!

    // Account for differences between Rails and Webpack Sass code.
    $rails: true;

    // Included from bootstrap-sprockets gem and loaded in app/assets/javascripts/application.rb
    @import 'bootstrap-sprockets';

    // Customizations - needs to be imported after bootstrap-sprocket but before bootstrap-custom!
    // The _pre-bootstrap.scss file is located under
    // client/assets/stylesheets, which has been added to the Rails asset
    // pipeline search path. See config/application.rb.
    @import 'pre-bootstrap';

    // These scss files are located under client/assets/stylesheets
    // (which has been added to the Rails asset pipeline search path in config/application.rb).
    @import 'bootstrap-custom';

    // This must come after all the boostrap styles are loaded so that these styles can override those.
    @import 'post-bootstrap';

  DATA
end

def bootstrap_related_js_contents
  <<-DATA.strip_heredoc

    // bootstrap-sprockets depends on generated/vendor-bundle for jQuery.
    //= require bootstrap-sprockets

  DATA
end
