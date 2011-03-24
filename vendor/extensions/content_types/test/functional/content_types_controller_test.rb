require File.dirname(__FILE__) + '/../test_helper'

# Re-raise errors caught by the controller.
ContentTypesController.class_eval { def rescue_action(e) raise e end }

class ContentTypesControllerTest < Test::Unit::TestCase
  fixtures :content_types, :content_type_parts
  test_helper :login, :difference
  def setup
    @controller = ContentTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @host = "redken.local"
    login_as :developer
  end

  # Replace this with your real tests.
  def test_should_require_login_for_all_actions
    logout
    assert_requires_login { get :index }
    assert_requires_login { get :new }
    assert_requires_login { get :edit, :id => 1 }
    assert_requires_login { post :create }
    assert_requires_login { put :update }
    assert_requires_login { delete :destroy }
  end
  
  def test_should_require_developer_or_admin_privileges
    login_as :existing
    assert_requires_privileges { get :index }
    assert_requires_privileges { get :new }
    assert_requires_privileges { get :edit, :id => 1 }
    assert_requires_privileges { post :create }
    assert_requires_privileges { put :update }
    assert_requires_privileges { delete :destroy }    
  end
  
  def test_index_should_list_all_content_types
    get :index
    assert_response :success
    assert_not_nil assigns(:content_content_types)
    assert_equal ContentType.count, assigns(:content_content_types).size
  end
  
  def test_new_should_show_form_for_new_content_type
    get :new
    assert_response :success
    assert_not_nil assigns(:content_content_type)
    assert assigns(:content_content_type).new_record?
    assert_tag :form, :attributes => {:action => /\/admin\/content_types$/ }
  end
  
  def test_create_should_create_a_new_content_type
    assert_difference ContentType, :count do
      post :create, :content_type => {:name => "Test content_type", :content => "testing", :layout_id => 1}
      assert_response :redirect
      assert_redirected_to :controller => "content_types", :action => "index"
      assert_not_nil assigns(:content_content_type)
    end
  end
  
  def test_edit_should_load_existing_content_type_and_show_form
    get :edit, :id => 1
    assert_response :success
    assert_not_nil assigns(:content_content_type)
    assert_equal content_types(:one), assigns(:content_content_type)
    assert_tag :form, :attributes => {:action => /\/admin\/content_types\/1$/ }
  end
  
  def test_update_should_change_existing_content_type
    put :update, :id => 1, :content_type => {:name => "Test content_type"}
    assert_response :redirect
    assert_redirected_to :controller => "content_types", :action => "index"
    assert_not_nil assigns(:content_content_type)
    assert_equal 1, assigns(:content_content_type).id
    assert_equal "Test content_type", assigns(:content_content_type).name
  end
  
  def test_destroy_should_destroy_existing_content_type
    assert_difference ContentType, :count, -1 do
      delete :destroy, :id => 1
      assert_response :redirect
      assert_redirected_to :controller => "content_types", :action => "index"
      assert_not_nil assigns(:content_content_type)
    end
  end
  
  private
    def assert_requires_privileges
      yield if block_given?
      assert_response :redirect
      assert_redirected_to :controller => "admin/page", :action => "index"
    end
end
