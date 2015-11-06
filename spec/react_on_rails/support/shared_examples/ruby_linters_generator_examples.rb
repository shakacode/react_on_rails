shared_examples "ruby_linters" do
  it "adds linter gems" do
    assert_file("Gemfile") do |content|
      expected = <<-GEMS.strip_heredoc
        # require: false is necessary for the linters as we only want them loaded
        # when used by the linting rake tasks.
        group :development do
          gem("rubocop", require: false)
          gem("ruby-lint", require: false)
          gem("scss_lint", require: false)
        end
      GEMS
      assert_match(expected, content)
    end
  end

  it "copies linting and auditing tasks" do
    %w(lib/tasks/brakeman.rake
       lib/tasks/ci.rake
       lib/tasks/linters.rake).each { |file| assert_file(file) }
  end
end
