require File.dirname(__FILE__) + "/../test_helper"

class PublishTreeTest < Test::Unit::TestCase
  
  def setup
    @page = pages(:documentation)
    UserActionObserver.current_user = users(:another)
  end
  
  def test_should_publish_tree
    assert_not_nil @page.draft
    @page.publish_tree
    assert_nil @page.draft(true)
    assert @page.recurse_collecting(&:children).flatten.all?(&:published?)
  end
  
  def test_should_draft_tree
    @page = pages(:assorted)
    @page.unpublish_tree
    @page.recurse_collecting(&:children).flatten.each do |p|
      assert_equal Status[:draft], p.status
    end
  end
end