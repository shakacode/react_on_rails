# frozen_string_literal: true

require_relative "../rails_helper"

describe "Hello Server", :js do
  it "renders the React Server Component" do
    visit "/hello_server"
    expect(page).to have_text("Hello, React on Rails Pro!")
    expect(page).to have_text("This is a React Server Component")
  end
end
