require File.dirname(__FILE__) + '/../test_helper'

class FormBuilderExtensionTest < Test::Unit::TestCase
  
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::TagHelper
  include AssetManager::FormBuilderExtensions
  
  def setup
    @template = self
    @object = stub("AttachmentHolder")
    @object.stubs(:attachment_id).returns(1)
    @object_name = 'attachment_holder'
  end
  
  def test_outputs_asset_field
    @object.stubs(:attachment).returns(nil)
    html = asset_field(:attachment_id)
    assert_match %r(<input), html
    assert_match %r(type="text"), html
    assert_match %r(value="1"), html
    assert_match %r(class="asset-manager-field"), html
  end
  
  def test_outputs_asset_field_with_preview
    @object.stubs(:attachment).returns(stub(:public_filename => '/path/to/asset'))
    html = asset_field(:attachment_id)
    assert_match %r(<img), html
    assert_match %r(src="/path/to/asset"), html
  end
  
end