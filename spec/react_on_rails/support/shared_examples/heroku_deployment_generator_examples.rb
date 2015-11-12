shared_examples "heroku_deployment" do
  it "should add heroku deployment files" do
    assert_file("Procfile")
    assert_file(".buildpacks")
    assert_file("config/unicorn.rb")
  end

  it "should add heroku production gems" do
    assert_file("Gemfile") do |contents|
      assert_match("gem 'rails_12factor', group: :production", contents)
      assert_match("gem 'unicorn'", contents)
    end
  end
end
