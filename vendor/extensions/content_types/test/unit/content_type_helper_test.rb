require File.dirname(__FILE__) + '/../test_helper'

class Asset < ActiveRecord::Base; end

class ContentTypeHelperTest < Test::Unit::TestCase
  include ContentTypes::Helper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormTagHelper
  fixtures :content_type_parts, :part_types
  test_helper :login
  
  def setup
    @part = content_type_parts(:four)
    @part.stubs(:content).returns('/0000/0001/bogus.png')
    PartType.any_instance.stubs(:field_type).returns('asset')
    Asset.stubs(:find).raises(ActiveRecord::RecordNotFound)
    @page = Page.new(:content_type_id => 1)
    @page.stubs(:part).with(anything).returns(@part)
    @template = self
  end
  
  def test_missing_asset_should_not_raise_error
    assert_nothing_raised do
      html = content_type_part_field @part, 'Bogus_Asset'
      assert_match %r(class="asset-manager-field"), html
      assert_match %r(name="part\[Bogus_Asset\]\[content\]"), html
    end
  end
  
end