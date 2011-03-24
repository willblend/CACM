require File.dirname(__FILE__) + '/../test_helper'

Admin::PageController.class_eval { def rescue_action(e); raise e; end }

class ContentTypesControllerExtensionsTest < Test::Unit::TestCase
  fixtures  :content_types, :content_type_parts, :part_types
  test_helper :login
  def setup
    @controller = Admin::PageController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    login_as :existing
    @page = Page.new(:content_type_id => 1)
    Page.stubs(:find).returns(@page)
    Page.any_instance.stubs(:url).returns('/path/to/page')
  end
  
  def test_should_render_specific_input_types_based_on_part_types
    get :edit, :id => 1
    assert_response :success
    assert_not_nil assigns(:page)
    assert_equal @page, assigns(:page)
    
    # Test for WYSIWYG area
    assert_tag :input, :attributes => {
                :type => "hidden", 
                :name => /part\[\d+\]\[name\]/, 
                :value => "Part 1"}
    assert_tag :textarea, :attributes => {
                :class => "textarea",
                :name => /part\[\d+\]\[content\]/,
                :style => "width: 100%" }
    
    # Test for plain text area
    assert_tag :input, :attributes => {
                :type => "hidden", 
                :name => /part\[\d+\]\[name\]/, 
                :value => "extended"}
    assert_tag :textarea, :attributes => {
                :class => "plain",
                :name => /part\[\d+\]\[content\]/ }
    
    # Test for boolean checkbox
    assert_tag :input, :attributes => {
                :type => "hidden", 
                :name => /part\[\d+\]\[name\]/, 
                :value => "featured?"}
    assert_tag :input, :attributes => {
                :name => /part\[\d+\]\[content\]/,
                :type => "checkbox",
                :value => "true" }
    assert_tag :input, :attributes => {
                :name => /part\[\d+\]\[content\]/,
                :type => "hidden",
                :value => "false" }
    
    # Test for hidden field
    assert_tag :input, :attributes => {
                :type => "hidden", 
                :name => /part\[\d+\]\[name\]/, 
                :value => "Feature image"}
    assert_tag :input, :attributes => {
                :type => "hidden",
                :name => /part\[\d+\]\[content\]/ }
    
    # Test for text field
    assert_tag :input, :attributes => {
                :type => "hidden", 
                :name => /part\[\d+\]\[name\]/, 
                :value => "Tagline"}
    assert_tag :input, :attributes => {
                :type => "text",
                :name => /part\[\d+\]\[content\]/,
                :style => "width: 500px;" }
  end
  
  def test_should_override_page_class_when_not_blank
    get :edit, :id => 1
    assert_response :success
    assert_not_nil assigns(:page)
    
    assert_no_tag :input, :attributes => {
                :type => "hidden",
                :name => "page[class_name]"}
    
    @page = Page.new(:content_type_id => 2)
    Page.stubs(:find).returns(@page)
    
    get :edit, :id => 1
    assert_response :success
    assert_not_nil assigns(:page)
    
    assert_tag :input, :attributes => {
                :type => "hidden",
                :name => "page[class_name]",
                :value => "FileNotFoundPage"}
  end
end
