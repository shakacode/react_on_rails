require 'rails_helper'

RSpec.feature "DynamicHTMLTag", type: :feature do
  scenario "Able to see dynamic HTML tag, SPAN", :js => true do
    visit('/hello_world')
    expect(page).to have_selector("span")
  end
end
