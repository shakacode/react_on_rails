class Sample
  # ruby method
  def some_meth; end

  # aliasing a C method
  alias :remove :gleezor

  protected

  def gleezor_1; end
  alias :remove_1 :gleezor_1

  private

  def gleezor_2; end

  alias :remove_2 :gleezor_2
end
