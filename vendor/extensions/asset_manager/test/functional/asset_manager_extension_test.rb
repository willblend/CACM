require File.dirname(__FILE__) + '/../test_helper'

class AssetManagerExtensionTest < Test::Unit::TestCase
   
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'asset_manager'), AssetManagerExtension.root
    assert_equal 'Asset Manager', AssetManagerExtension.extension_name
    assert ActiveRecord::Base.included_modules.include?(AssetManager::BelongsToAsset)
    assert ActionView::Helpers::FormBuilder.included_modules.include?(AssetManager::FormBuilderExtensions)
  end
  
end
