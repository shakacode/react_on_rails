When(/^I click on a missing link$/) do
  click_on "you'll never find me"
end

When(/^I click on a missing link on a different page in a different session$/) do
  using_session :different_session do
    visit '/different_page'
    click_on "you'll never find me"
  end
end

When(/^I visit "([^"]*)"$/) do |path|
  visit path
end

Then(/^I trigger an unhandled exception/) do
  raise "you can't handle me"
end
