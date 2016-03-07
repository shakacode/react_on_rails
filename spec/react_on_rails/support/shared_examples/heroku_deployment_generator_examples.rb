shared_examples "heroku_deployment" do
  it "should add heroku deployment files" do
    assert_file("Procfile")
  end

  it "should add heroku production gems" do
    assert_file("Gemfile") do |contents|
      assert_match("gem 'rails_12factor', group: :production", contents)
    end
  end
end
