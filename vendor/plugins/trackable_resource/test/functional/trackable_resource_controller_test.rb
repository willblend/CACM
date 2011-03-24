require File.join(File.dirname(__FILE__), '/../test_helper')

# require Hit Model
require File.dirname(__FILE__) + '/../../lib/hit'

class TestController < ActionController::Base  
  trackable_resource :resource
  trackable_resource :asset
  trackable_resource :rando
  def success; end
  
  def redirect
    redirect_to :action => 'success'
  end
  
end

class Resource < ActiveRecord::Base
  has_many :assets  
  trackable_resource
end

class Asset < ActiveRecord::Base
  belongs_to :resource
  trackable_resource
end

class Rando < ActiveRecord::Base; end

TestController.template_root = File.dirname(__FILE__) + "/../fixtures"
TestController.class_eval { def rescue_action(e) raise e end }

class TrackableResourceTest < Test::Unit::TestCase
  fixtures :resources, :assets, :randos

  def setup
    @controller = TestController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @resource = resources(:one)
  end
  
  def test_success
    get :success
    assert_response :success
  end
  
  def test_redirect
    get :redirect
    assert_response :redirect
    assert_redirected_to :action => 'success'
  end
  
  def test_should_extend_controller_with_trackable_method
    assert TestController.instance_methods.include?("track_resource")
    assert TestController.instance_methods.include?("track_asset")    
  end
  
  def test_should_track_resource
    resource = resources(:one)
    get :track_resource, :id => resource.id
    assert @request.remote_ip
    assert assigns(:resource)
    assert assigns(:hit)
    assert_equal resource, assigns(:resource)
    assert_equal @request.remote_ip, assigns(:hit).user_ip
    assert_equal @request.env['HTTP_USER_AGENT'], assigns(:hit).user_agent
    assert_equal @request.env['HTTP_REFERER'], assigns(:hit).referer
  end
  
  def test_should_track_asset
    asset = assets(:one)
    get :track_asset, :id => asset.id
    assert @request.remote_ip
    assert assigns(:asset)
    assert assigns(:hit)
    assert_equal asset, assigns(:asset)
    assert_equal @request.remote_ip, assigns(:hit).user_ip
    assert_equal @request.env['HTTP_USER_AGENT'], assigns(:hit).user_agent
    assert_equal @request.env['HTTP_REFERER'], assigns(:hit).referer   
  end
  
  def test_should_track_resource_using_js_format
    resource = resources(:one)
    get :track_resource, :id => resource.id, :format => 'js'
    assert_response :success
    assert @request.remote_ip
    assert assigns(:resource)
    assert assigns(:hit)
    assert_equal resource, assigns(:resource)
    assert_equal @request.remote_ip, assigns(:hit).user_ip
    assert_equal @request.env['HTTP_USER_AGENT'], assigns(:hit).user_agent
    assert_equal @request.env['HTTP_REFERER'], assigns(:hit).referer
  end
  
  def test_should_use_custom_find
    TestController.class_eval do
      trackable_resource :resource, :find => "Resource.find(params[:resource_id])"
    end
    
    resource = resources(:one)
    get :track_resource, :resource_id => resource.id
    assert @request.remote_ip
    assert assigns(:resource)
    assert_equal resource, assigns(:resource)
  end
  
  def test_should_raise_error_when_trackable_resource_is_not_defined
    assert_raise DigitalPulp::ActionController::Extensions::TrackableResource::TrackableResourceControllerError do
      rando = randos(:one)
      get :track_rando, :id => rando.id
    end
  end
  
  def test_should_raise_error_when_resource_dne
    assert_raise ActiveRecord::RecordNotFound do
      resource = resources(:one)
      get :track_resource, :id => 134234
    end
  end
  
end
