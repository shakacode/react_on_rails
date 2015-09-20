require "rails_helper"

feature "Test React Components" do
  it "Ensure that entered text is displayed", js: true do
    visit root_path
    find(:xpath, '//input[@data-reactid=".0.1.1"]').set("1 Test Name")
    expect(page).to have_content("Redux Hello, 1 Test Name!")

    find(:xpath, '//input[@data-reactid=".1.1.1"]').set("2 Test Name")
    expect(page).to have_content("Hello, 2 Test Name!")

    find(:xpath, '//input[@data-reactid=".2.1.1"]').set("3 Test Name")
    expect(page).to have_content("Hello, 3 Test Name!")

    find(:xpath, '//input[@data-reactid=".3.1.1"]').set("4 Test Name")
    expect(page).to have_content("Hello, 4 Test Name!")

    find(:xpath, '//input[@data-reactid=".4.1.1"]').set("5 Test Name")
    expect(page).to have_content("Hello, 5 Test Name!")

    find(:xpath, '//input[@data-reactid=".5.1.1"]').set("6 Test Name")
    expect(page).to have_content("Hello ES5, 6 Test Name!")

    visit focused_path
    find(:xpath, '//input').set("Focused Name")
    expect(page).to have_content("Hello, Focused Name!")
  end
end
