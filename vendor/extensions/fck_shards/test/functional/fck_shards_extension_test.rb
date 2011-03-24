require File.dirname(__FILE__) + '/../test_helper'

class FckShardsExtensionTest < Test::Unit::TestCase
  
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'fck_shards'), FckShardsExtension.root
    assert_equal 'Fck Shards', FckShardsExtension.extension_name
  end

  def test_installs_fck_in_page
    admin = Radiant::AdminUI.instance
    assert admin.page.edit.main.include?("fck_editor")
  end
end
