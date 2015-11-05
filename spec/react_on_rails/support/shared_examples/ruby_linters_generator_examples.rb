shared_examples ":ruby_linters" do
  it "adds linter gems" do
    linter_gems = <<-GEMS
# require: false is necessary for the linters as we only want them loaded
# when used by the linting rake tasks.
group :development do
  gem("rubocop", require: false)
  gem("ruby-lint", require: false)
  gem("scss_lint", require: false)
end
GEMS

    assert_file("Gemfile") do |content|
      assert_match(linter_gems, content)
    end
  end

  it "copies linting and auditing tasks" do
    assert_file "lib/tasks/brakeman.rake"
    assert_file "lib/tasks/ci.rake"
    assert_file "lib/tasks/linters.rake"
  end
end
