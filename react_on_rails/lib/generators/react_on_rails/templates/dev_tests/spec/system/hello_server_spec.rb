# frozen_string_literal: true

require_relative "../rails_helper"

describe "Hello Server", :js do
  it "renders the React Server Component" do
    visit "/hello_server"
    expect(page).to have_text("Hello, React on Rails Pro!")
    expect(page).to have_text("How is this different from SSR?")
  end

  it "renders the interactive LikeButton client component" do
    visit "/hello_server"
    expect(page).to have_button("👍 Like")
    expect(page).to have_text("0 likes")
  end
end
