require File.dirname(__FILE__) + '/../test_helper'

class WorkflowExtensionTest < Test::Unit::TestCase
  
  def test_initialization
    assert_equal File.join(File.expand_path(RAILS_ROOT), 'vendor', 'extensions', 'workflow'), WorkflowExtension.root
    assert_equal 'Workflow', WorkflowExtension.extension_name
  end
  
  def test_page_model_extensions
    [Page, Page.descendants].flatten.each do |klass| 
      @page = klass.new
      assert_respond_to @page, :draft
      assert_respond_to @page, :draft_parent
      assert_respond_to @page, :is_draft?
      assert_respond_to @page, :find_by_url_with_drafts
      assert_respond_to @page, :children_with_drafts
      assert_respond_to @page, :status_with_drafts
      assert_respond_to @page, :build_draft_with_attribute_cloning
      assert_respond_to @page, :publish_draft
    end
  end
  
  def test_publish_tree_extensions
    @page = Page.new
    assert_respond_to @page, :publish_tree
    assert_respond_to @page, :unpublish_tree
  end
  
  def test_page_controller_extensions
    @controller = Admin::PageController.new
    assert_respond_to @controller, :edit_with_drafts
  end
end
