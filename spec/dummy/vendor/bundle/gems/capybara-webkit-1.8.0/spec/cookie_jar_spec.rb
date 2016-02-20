require 'spec_helper'
require 'capybara/webkit/cookie_jar'

describe Capybara::Webkit::CookieJar do
  let(:browser) {
    browser = double("Browser")
    browser.stub(:get_cookies) { [
        "cookie1=1; domain=.example.org; path=/",
        "cookie1=2; domain=.example.org; path=/dir1/",
        "cookie1=3; domain=.facebook.com; path=/",
        "cookie2=4; domain=.sub1.example.org; path=/",
      ] }
    browser
  }

  subject { Capybara::Webkit::CookieJar.new(browser) }

  describe "#find" do
    it "returns a cookie object" do
      subject.find("cookie1", "www.facebook.com").domain.should eq ".facebook.com"
    end

    it "returns the right cookie for every given domain/path" do
      subject.find("cookie1", "example.org").value.should eq "1"
      subject.find("cookie1", "www.facebook.com").value.should eq "3"
      subject.find("cookie2", "sub1.example.org").value.should eq "4"
    end

    it "does not return a cookie from other domain" do
      subject.find("cookie2", "www.example.org").should eq nil
    end

    it "respects path precedence rules" do
      subject.find("cookie1", "www.example.org").value.should eq "1"
      subject.find("cookie1", "www.example.org", "/dir1/123").value.should eq "2"
    end
  end

  describe "#[]" do
    it "returns the first matching cookie's value" do
      subject["cookie1", "example.org"].should eq "1"
    end

    it "returns nil if no cookie is found" do
      subject["notexisting"].should eq nil
    end
  end
end
