require File.dirname(__FILE__) + "/../test_helper"

class WorkflowControllerTest < Test::Unit::TestCase
  
  def setup
    @controller = WorkflowController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    login_as(:existing)
  end

  def test_should_update_status_of_draft
    page = pages(:documentation)
    draft = pages(:documentation_draft)
    post :update_status, :id => page.id, :status_id => Status[:review].id
    assert_response :redirect
    assert_equal draft.id, assigns(:page).id
    assert_equal Status[:review].id, assigns(:page).status_id
  end
  
  def test_should_update_status_of_non_draft
    page = pages(:books)
    post :update_status, :id => page.id, :status_id => Status[:draft].id
    assert_response :redirect
    assert_equal page.id, assigns(:page).id
    assert_equal Status[:draft], assigns(:page).status
  end
  
  def test_should_destroy_draft_on_revert
    page = pages(:documentation)
    assert_not_nil page.draft
    post :revert, :id => page.id
    assert_not_nil assigns(:page)
    assert assigns(:page).draft.frozen?
    assert_response :redirect
  end
  
  def test_should_publish_draft
    page = pages(:documentation)
    assert_not_nil page.draft
    post :publish, :id => page.id
    assert_not_nil assigns(:page)
    assert_equal Status[:published], assigns(:page).status
    assert_nil assigns(:page).draft(true)
    assert !assigns(:cache).response_cached?(assigns(:page).url)
    assert_response :redirect
  end
  
  def test_should_set_published_when_no_draft
    page = pages(:gallery_draft)
    assert_nil page.draft
    post :publish, :id => page.id
    assert_not_nil assigns(:page)
    assert_equal Status[:published], assigns(:page).status
    assert_response :redirect
  end
  
  def test_should_publish_tree
    page = pages(:documentation)
    assert_not_nil page.draft
    post :publish_tree, :id => page.id
    assert_not_nil assigns(:page)
    assert_nil assigns(:page).draft
    assert_equal Status[:published], assigns(:page).status
    assert assigns(:page).recurse_collecting(&:children).flatten.all? {|p| p.status == Status[:published]}
    assert !assigns(:page).recurse_collecting(&:children).flatten.any?{|p| assigns(:cache).response_cached?(p.url)}
    assert_response :redirect
  end
  
  def test_should_draft_tree
    page = pages(:assorted)
    assert_equal Status[:published], page.status
    post :draft_tree, :id => page.id
    assert_not_nil assigns(:page)
    assert_equal page.id, assigns(:page).id
    assert !assigns(:page).recurse_collecting(&:children).flatten.any?(&:published?)
    assert !assigns(:page).recurse_collecting(&:children).flatten.any?{|p| assigns(:cache).response_cached?(p.url)}
    assert_response :redirect
  end
end
