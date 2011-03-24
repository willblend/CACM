require File.dirname(__FILE__) + '/../test_helper'

class ContentTypesExtensionTest < Test::Unit::TestCase
   
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'content_types'), ContentTypesExtension.root
    assert_equal 'Content Types', ContentTypesExtension.extension_name
  end
   
  def test_should_load_plugins
    assert defined? Haml
    assert defined? Resourceful
  end
  
  def test_should_add_associations
    assert Page.included_modules.include?(ContentTypes::Associations)
    assert Page.new.respond_to?(:content_type)
    assert Page.new.respond_to?(:content_type=)
  end
  
  def test_should_add_controller_modifications
    assert Admin::PageController.included_modules.include?(ContentTypes::ControllerExtensions)
    assert Admin::PageController.new.respond_to?(:load_content_type)
  end
end
