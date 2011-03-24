require File.dirname(__FILE__) + '/../test_helper'

class ContentTypePartTest < Test::Unit::TestCase
  fixtures :part_types
  
  def setup
    @content_type_part = ContentTypePart.new :content_type_id => 1, :name => "extended", :filter_id => nil, :part_type_id => 1
  end
  
  def test_should_require_name
    @content_type_part.name = nil
    assert !@content_type_part.valid?
    assert_not_nil @content_type_part.errors.on(:name)
  end
  
  def test_should_disallow_body_for_name
    @content_type_part.name = 'body'
    assert !@content_type_part.valid?
    assert_not_nil @content_type_part.errors.on(:name)
  end
  
  def test_should_require_part_type_id
    @content_type_part.part_type_id = nil
    assert !@content_type_part.valid?
    assert_not_nil @content_type_part.errors.on(:part_type_id)
  end
  
  def test_should_assign_part_type_by_name
    @content_type_part.part_type_name = "Boolean"
    assert_not_nil @content_type_part.part_type
    assert_equal part_types(:boolean), @content_type_part.part_type
  end
  
end


