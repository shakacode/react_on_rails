# frozen_string_literal: true

require_relative "../rails_helper"

describe "Hello Server", :js do
  it "renders the React Server Component" do
    visit "/hello_server"
    expect(page).to have_text("Hello, React on Rails Pro!")
    expect(page).to have_text("Render data on the server and hydrate only the interactive parts")
    expect(page).to have_text("Server rendered at:")
    expect(page).to have_button("Celebrate streaming RSC (7)")

    click_button("Celebrate streaming RSC (7)")
    expect(page).to have_button("Celebrate streaming RSC (8)")
  end
end
