shared_examples "generator_errors" do
  it "initializes GeneratorErrors singleton" do
    assert_equal GeneratorErrors, GeneratorErrors
  end

  it "has an errors method that returns an array" do
    assert_instance_of Array, GeneratorErrors.errors
  end

  it "has a method that can add errors" do
    GeneratorErrors.add_error "Test error"
    assert_instance_of Array, GeneratorErrors.errors
    assert_includes GeneratorErrors.errors, "Test error"
  end

  it "adds setup file error to errors" do
    file = "test_file"
    data = <<-DATA.strip_heredoc
      test data
    DATA
    GeneratorErrors.add_error(return_setup_file_error(file, data))
    error = ""
    error << "** #{file} was not found.\n"
    error << "Please add the following content to your #{file} file:\n"
    error << "\n#{data}\n"
    assert_includes GeneratorErrors.errors, error
  end

  it "shows gitignore error if gitignore does not exist" do
    file = ".gitignore"
    data = <<-DATA.strip_heredoc
      # React on Rails
      npm-debug.log
      node_modules

      # Generated js bundles
      /app/assets/javascripts/generated/*
    DATA
    error = ""
    error << "** #{file} was not found.\n"
    error << "Please add the following content to your #{file} file:\n"
    error << "\n#{data}\n"
    assert_includes GeneratorErrors.errors, error
  end
end
