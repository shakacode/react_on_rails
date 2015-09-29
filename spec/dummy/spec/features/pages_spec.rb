require "rails_helper"

feature "Pages" do
  background do
    visit root_path
  end

  scenario "status 200" do
    expect(page.status_code).to eq 200
  end
end
