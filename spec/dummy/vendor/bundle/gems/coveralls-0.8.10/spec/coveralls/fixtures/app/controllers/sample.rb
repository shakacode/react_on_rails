# Foo class
class Foo
  def initialize
    @foo = 'baz'
  end

  # :nocov:
  def bar
    @foo
  end
  # :nocov:
end
