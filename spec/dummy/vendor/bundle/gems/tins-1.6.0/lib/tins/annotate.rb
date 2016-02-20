module Tins::Annotate
  def annotate(name)
    singleton_class.class_eval do
      define_method(name) do |annotation|
        instance_variable_set "@__annotation_#{name}__", annotation
      end

      define_method("#{name}_of") do |method_name|
        __send__("#{name}_annotations")[method_name]
      end

      define_method("#{name}_annotations") do
        if instance_variable_defined?("@__annotation_#{name}_annotations__")
          instance_variable_get "@__annotation_#{name}_annotations__"
        else
          instance_variable_set "@__annotation_#{name}_annotations__", {}
        end
      end

      old_method_added = instance_method(:method_added)
      define_method(:method_added) do |method_name|
        old_method_added.bind(self).call method_name
        if annotation = instance_variable_get("@__annotation_#{name}__")
          __send__("#{name}_annotations")[method_name] = annotation
        end
        instance_variable_set "@__annotation_#{name}__", nil
      end
    end
  end
end
