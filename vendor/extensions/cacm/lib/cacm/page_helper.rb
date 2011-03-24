module CACM::PageHelper
  
  def self.included(base)
    base.class_eval do
      alias_method_chain :tag_reference, :no_rendering
      # So that we don't render a bunch of useless tag references on page edit.
    end
  end
  
  def tag_reference_with_no_rendering(classname)
    return nil # No rendering, indeed
  end
  
end