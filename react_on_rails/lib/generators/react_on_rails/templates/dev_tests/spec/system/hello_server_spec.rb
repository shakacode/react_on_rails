# frozen_string_literal: true

require_relative "../rails_helper"

describe "Hello Server", :js do
  it "renders the React Server Component" do
    visit "/hello_server"
    expect(page).to have_text("Hello, React on Rails Pro!")
    expect(page).to have_text("How is this different from SSR?")
  end

  it "does not emit RSC payload errors in the starter sample" do
    visit "/hello_server"
    expect(page.html).not_to include('"hasErrors":true')
    expect(page.html).not_to include("useState is not a function")
  end
end
