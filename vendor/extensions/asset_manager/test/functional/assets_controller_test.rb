require File.dirname(__FILE__) + '/../test_helper'

# Re-raise errors caught by the controller.
AssetsController.class_eval { def rescue_action(e) raise e end }

class AssetsControllerTest < Test::Unit::TestCase
  fixtures :assets
  test_helper :login, :difference
  
  def setup
    @controller = AssetsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as :existing
    
    @failing_asset = assets(:qt).dup
    @failing_asset.stubs(:save).returns(false)
    @failing_asset.stubs(:update_attributes).returns(false)
  end

  def test_should_require_login_for_all_actions
    logout
    assert_requires_login { get :index }
    assert_requires_login { get :show, :id => 1 }
    assert_requires_login { get :new }
    assert_requires_login { get :edit, :id => 1 }
    assert_requires_login { post :create }
    assert_requires_login { put :update }
    assert_requires_login { delete :destroy }
  end
  
  def test_index_should_list_all_assets
    get :index
    assert_response :success
    assert_not_nil assigns(:assets)
    assert_equal Asset.count, assigns(:assets).size
  end
  
  def test_new_should_allow_only_upload
    get :new
    assert_response :success
    assert_not_nil assigns(:asset)
    assert assigns(:asset).new_record?
    assert_tag :input, :attributes => {:name => "asset[file]"}
    %w{description expires_on}.each do |field|
      assert_no_tag :input, :attributes => {:name => "asset[#{field}]"}
    end
  end
  
  def test_create_should_receive_upload_and_redirect_to_edit
    assert_difference Asset, :count do
      post :create, :asset => {:file => file_upload("book.png", "image/png")}, :format => 'html', :type => 'all'
      assert_response :redirect
      assert_not_nil assigns(:asset)
      assert_equal "image/png", assigns(:asset).content_type
      assert_equal "book.png", assigns(:asset).filename
    end
    assert_redirected_to formatted_edit_asset_path(:format => 'html', :type => 'all', :id => assigns(:asset).id, :just_created => 1)
  end
  
  def test_should_convert_zipfiles_to_zip_asset
    post :create, :asset => {:file => file_upload("testdata.zip", "application/zip")}, :format => 'html', :type => 'all'
    assert assigns(:asset).is_a?(ZipAsset)
  end
  
  def test_edit_should_load_asset_and_display_fields_for_metadata
    get :edit, :id => 1
    assert_response :success
    assert_not_nil assigns(:asset)
    assert_equal assets(:png), assigns(:asset)
    assert_no_tag :input, :attributes => { :name => /uploaded_data/ }
    assert_tag :textarea, :attributes => { :name => "asset[description]" }
    assert_tag :input, :attributes => { :name => /expires_on/ }
  end
  
  def test_edit_should_offer_redo_if_the_asset_was_just_created
    get :edit, :id => 2, :just_created => 1
    assert_response :success

    ### taking this out momentarily until we complete the UI more -JSB
    # assert_tag :p, :attributes => {:class => "just_created"}
    # assert_tag :form, :attributes => {:class => "button-to", :action => /\/2\?undo=1/ }
  end
  
  def test_update_should_update_metadata
    put :update, :id => 2, :asset => {:description => "New description"}, :commit => "Save metadata"
    assert_not_nil assigns(:asset)
    assert_response :redirect
    assert_redirected_to formatted_asset_path(:id => 2, :format => 'html', :type => 'all')
    assert_equal "New description", assigns(:asset).description
  end
  
  def test_update_should_display_message_and_redisplay_when_updating_metadata_fails
    Asset.expects(:find).returns(@failing_asset)
    put :update, :id => 2, :commit => "Save metadata", :asset => {}
    assert_not_nil flash[:error]
    assert_template 'edit'
  end
  
  def test_update_should_redirect_to_metadata_screen_when_replacing
    put :update, :id => 2, :commit => "Upload & Replace", :asset => {}
    assert_not_nil assigns(:asset)
    assert_response :redirect
    assert_redirected_to formatted_edit_asset_path(:id => 2, :format => 'html', :type => 'all')
  end
  
  def test_update_should_display_message_and_redirect_to_show_when_replacing_fails
    Asset.expects(:find).returns(@failing_asset)
    put :update, :id => 2, :commit => "Upload & Replace", :asset => {}
    assert_not_nil flash[:error]
    assert_template 'edit'
  end
  
  def test_destroy_should_destroy_asset
    assert_difference Asset, :count, -1 do
      delete :destroy, :id => 2
      assert_response :redirect
      assert_redirected_to "/admin/assets"
    end
  end
  
  def test_destroy_should_destroy_asset_and_redirect_to_new_on_undo
    assert_difference Asset, :count, -1 do
      delete :destroy, :id => 2, :undo => 1
      assert_response :redirect
      assert_redirected_to formatted_assets_path(:format => 'html', :type => 'all')
    end
  end
  
  def test_index_should_display_a_list_of_found_items_when_searched
    get :index, :search => "a"
    assert_response :success
    assert_not_nil assigns(:assets)
    assigns(:assets).each do |a|
      assert_tag :attributes => {:id => "asset_#{a.id}"}
    end
  end
  
  def test_index_should_restrict_search_to_asset_subclass
    Asset.expects(:search).with('image', nil, :conditions => { :class_name => 'ImageAsset' }).returns(WillPaginate::Collection.new(1,2,3))
    get :index, :search => "image", :type => 'image'
  end
  
  def test_index_should_search_all_assets_if_not_scoped_by_type
    Asset.expects(:search).with('image', nil, nil).returns(WillPaginate::Collection.new(1,2,3))
    get :index, :search => "image"
  end

  def test_usage_should_display_a_list_of_expired_items_for_expiration_report
    get :usage
    assert_response :success
    assert_not_nil assigns(:assets)
    assert_included assigns(:assets), assets(:expired)
    assert_not_included assigns(:assets), assets(:png)
    assert_template 'index'
    assigns(:assets).each do |a|
      assert_tag :attributes => {:id => "asset_#{a.id}"}
    end
  end
  
  def test_should_accept_swfUpload_param
    assert_difference Asset, :count do
      post :create, :Filedata => file_upload("book.png", "image/png"), :format => 'html', :type => :all
    end
  end
  
  def test_should_accept_normal_params_along_with_swfUpload
    ZipAsset.any_instance.expects(:unzip?)
    post :create, :asset => { :unzip => 1 }, :Filedata => file_upload('testdata.zip', 'application/zip'), :format => 'html', :type => :all
    assert_equal 1, assigns(:asset).unzip
  end
  
  def test_index_should_display_a_list_of_found_items_when_index_selected
    get :index, :index => "v"
    assert_response :success
    assert_not_nil assigns(:assets)
    assigns(:assets).each do |a|
      assert_tag :attributes => {:id => "asset_#{a.id}"}
    end
  end

  def test_index_should_display_a_list_of_found_items_when_type_selected
    get :index, :type => "image"
    assert_response :success
    assert_not_nil assigns(:assets)
    assigns(:assets).each do |a|
      assert_tag :attributes => {:id => "asset_#{a.id}"}
    end
  end
  
  def test_recent_should_order_by_created_at
    
  end

end
