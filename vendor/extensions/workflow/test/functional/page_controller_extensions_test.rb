require File.dirname(__FILE__) + "/../test_helper"

class PageControllerExtensionsTest < Test::Unit::TestCase

  def setup
    @controller = Admin::PageController.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
    login_as(:existing)
  end

  def test_should_get_non_draft_homepage
    homepage = pages(:homepage)
    homepage.build_draft.save!
    get :index
    assert_response :success
    assert_not_nil assigns(:homepage)
    assert_equal homepage, assigns(:homepage)
    assert !assigns(:homepage).is_draft?
  end

  def test_should_edit_draft_when_not_new
    page = pages(:assorted)
    get :edit, :id => page.id
    assert_response :success
    assert_not_nil assigns(:page)
    assert assigns(:page).is_draft?
    assert_equal page.id, assigns(:page).draft_of
  end
  
  def test_should_edit_draft_when_draft_exists
    base_page = pages(:documentation)
    draft_page = pages(:documentation_draft)
    get :edit, :id => base_page.id
    assert_response :success
    assert_not_nil assigns(:page)
    assert_equal draft_page, assigns(:page)
  end
  
  def test_should_publish_when_publish_button_clicked
    base_page = pages(:documentation)
    post :edit, :id => base_page.id, :page => page_params, :publish => "Publish now"
    assert_response :redirect
    base_page.reload
    assert_nil base_page.draft, "Draft not destroyed!"
  end
  
  def test_should_show_editing_when_draft_exists
    page = pages(:homepage)
    page.build_draft.save!
    get :index
    assert_tag :tr, :attributes => {:id => "page-1"}, :descendant => {
      :tag => 'td', :attributes => {:class => /edit-/}, :content => /Editing/
    }
  end
end
