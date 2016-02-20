# encoding: utf-8

# 1.8.x doesn't support public_send and we use it in spec,
# so we emulate it in this monkeypatch.
class Object
  def public_send(method, *args, &block)
    case method.to_s
    when *private_methods
      raise NoMethodError, "private method `#{method}' called for #{self}"
    when *protected_methods
      raise NoMethodError, "protected method `#{method}' called for #{self}"
    else
      send(method, *args, &block)
    end
  end unless method_defined?(:public_send)
end
