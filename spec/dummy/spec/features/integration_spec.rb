require "rails_helper"

feature "Shared Redux store example" do
  subject { page }
  background { visit root_path }

  shared_examples_for 'page in initial state' do
    it "Has correct heading and text inside the text input" do
      expect(page).to have_selector("h3", text: /\ARedux Hello, Mr. Server Side Rendering!\z/)
      expect(page).to have_selector("input[type='text'][value='Mr. Server Side Rendering']")
    end
  end

  context "With disabled JS" do
    it_behaves_like "page in initial state"
  end

  context "With enabled JS", :js do
    it_behaves_like "page in initial state"
  end
end
