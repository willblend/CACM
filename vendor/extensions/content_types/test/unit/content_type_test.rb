require File.dirname(__FILE__) + '/../test_helper'

class ContentTypeTest < Test::Unit::TestCase
  fixtures :content_types, :content_type_parts, :pages, :page_parts, :layouts
  test_helper :page, :page_part, :layout
  
  def setup
    @content_type = ContentType.new :name => "Article", :layout_id => 1
  end
  
  def test_defaults_should_be_valid
    assert_valid @content_type
  end
  
  def test_should_require_name
    @content_type.name = nil
    assert !@content_type.valid?, @content_type.errors.full_messages.to_sentence
  end
  
  def test_should_require_layout
    @content_type.layout_id = nil
    assert !@content_type.valid?, @content_type.errors.full_messages.to_sentence
  end
  
  def test_should_require_valid_page_class_name
    @content_type.page_class_name = "blah"
    assert !@content_type.valid?
    @content_type.page_class_name = "FileNotFoundPage"
    assert @content_type.valid?, @content_type.errors.full_messages.to_sentence
  end
  
  def test_should_create_content_type_parts_from_hash
    @content_type.content_type_parts = {'1' => {:name => "extended", :filter_id => nil, :part_type_id => 1}, '2' => {:name => "more", :filter_id => "Textile", :part_type_id => 3}}
    assert_valid @content_type
    assert_nil @content_type.instance_variable_get("@add_content_type_parts")
    assert !@content_type.content_type_parts.empty?
    assert_equal 2, @content_type.content_type_parts.size
  end
  
  def test_should_update_associated_pages_after_update
    @content_type = content_types(:one)
    @content_type.stubs(:pages).returns([pages(:homepage)])
    # Initial conditions
    assert_nil pages(:homepage).layout
    [:body, :extended, :summary, :sidebar].each do |part|
      assert_not_nil pages(:homepage).part(part)
    end
    # Run the update
    @content_type.update_attributes(:layout_id => 1, :page_class_name => "FileNotFoundPage")
    # Reload from DB
    pages(:homepage).reload
    pages(:homepage).parts(true)
    # Layout and class name was changed to match
    assert_equal @content_type.layout_id, pages(:homepage).layout_id
    assert_equal @content_type.page_class_name, pages(:homepage).class_name
    # Body part was updated
    assert_equal @content_type.content, pages(:homepage).part(:body).content
    # Irrelevant parts were deleted
    [:summary, :sidebar].each do |part|
      assert_nil pages(:homepage).part(part)
    end
  end
  
  def test_should_be_ordered_by_position_column
    assert_equal ContentType.find(:all).sort_by(&:position), ContentType.find(:all)
  end
  
  def test_should_respond_to_acts_as_list_modifiers
    %w{move_higher move_lower move_to_top move_to_bottom}.each do |action|
      assert_respond_to @content_type, action
    end
  end
  
  def test_should_not_update_pages_when_reordering
    @content_type = content_types(:one)
    ContentType.reordering do
      @content_type.expects(:pages).never
      @content_type.move_to_bottom
    end
  end
end
