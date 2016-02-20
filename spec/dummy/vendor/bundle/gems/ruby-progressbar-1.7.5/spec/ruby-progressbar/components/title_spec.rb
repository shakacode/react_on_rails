require 'rspectacular'
require 'ruby-progressbar/components/title'

class     ProgressBar
module    Components
describe  Title do
  it 'can use the default title if none is specified' do
    expect(Title.new.title).to eql Title::DEFAULT_TITLE
  end
end
end
end
