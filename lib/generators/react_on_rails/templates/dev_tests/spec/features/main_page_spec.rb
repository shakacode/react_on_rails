require_relative "../rails_helper"

feature "Main Page", js: true do
  scenario "the main page example works" do
    visit "/main_page"
    expect(heading).to have_text("Main Page")
    expect(message).to have_text("Stranger")
    name_input.set("John Doe")
    expect(message).to have_text("John Doe")
  end
end

private

def name_input
  page.first("input")
end

def message
  page.first(:css, "h3")
end

def heading
  page.first(:css, "h1")
end
