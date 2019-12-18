# frozen_string_literal: true

require_relative "../rails_helper"

feature "Hello World", js: true do
  scenario "the hello world example works" do
    visit "/hello_world"
    expect(heading).to have_text("Hello World")
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
