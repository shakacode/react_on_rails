class   ProgressBar
module  Components
class   Title
  DEFAULT_TITLE = 'Progress'

  attr_accessor :title

  def initialize(options = {})
    self.title = options[:title] || DEFAULT_TITLE
  end
end
end
end
