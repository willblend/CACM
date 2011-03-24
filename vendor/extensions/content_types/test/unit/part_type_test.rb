require File.dirname(__FILE__) + '/../test_helper'

class PartTypeTest < Test::Unit::TestCase
  fixtures :part_types

  def setup
    @part_type = PartType.new :name => "Boolean", :field_type => "check_box"
  end
  
  def test_should_require_name_to_be_present
    @part_type.name = nil
    assert !@part_type.valid?, "#{@part_type} was expected to be invalid but was valid"
    assert_not_nil @part_type.errors.on(:name)
  end
  
  def test_should_require_field_type_to_be_present
    @part_type.field_type = nil
    assert !@part_type.valid?, "#{@part_type} was expected to be invalid but was valid"
    assert_not_nil @part_type.errors.on(:field_type)
  end
  
  def test_should_require_field_type_to_be_a_valid_type
    @part_type.field_type = "foobar"
    assert !@part_type.valid?, "#{@part_type} was expected to be invalid but was valid"
    assert_not_nil @part_type.errors.on(:field_type)
  end
end
