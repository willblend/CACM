# http://depth-first.com/articles/2006/10/24/metaprogramming-with-ruby-mapping-java-packages-onto-ruby-modules

module Kernel

  def jrequire(qualified_class_name)
    java_class = Rjb::import(qualified_class_name)
    package_names = qualified_class_name.to_s.split('.')
    java_class_name = package_names.delete(package_names.last)
    new_module = self.class

    package_names.each do |package_name|
      module_name = package_name.capitalize

      if !new_module.const_defined?(module_name)
        new_module = new_module.const_set(module_name, Module.new)
      else
        new_module = new_module.const_get(module_name)
      end
    end

    return false if new_module.const_defined?(java_class_name)

    new_module.const_set(java_class_name, java_class)

    return true
  end
end
