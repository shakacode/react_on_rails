class A
  def a
    loop do
      raise "super-exception"
    end
  end
end

class B < A
  def a
    loop do
      super
    end
  end
end

B.new.a
