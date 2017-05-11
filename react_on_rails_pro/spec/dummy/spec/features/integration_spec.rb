require "rails_helper"

feature "Shared Redux store example" do
  subject { page }
  background { visit root_path }

  shared_examples_for "page in initial state" do
    it "Has correct heading and text inside the text input" do
      expect(page).to have_selector("h3", text: /\ARedux Hello, Mr. Server Side Rendering!\z/)
      expect(page).to have_selector("input[type='text'][value='Mr. Server Side Rendering']")
    end
  end

  context "with disabled JS" do
    it_behaves_like "page in initial state"
  end

  context "with enabled JS", :js do
    it_behaves_like "page in initial state"

    it "updates header in reaction to text input changes" do
      new_value = "new value"
      find("input[type='text']").set(new_value)
      expect(page).to have_selector("h3", text: /\ARedux Hello, #{new_value}!\z/)
    end
  end
end
