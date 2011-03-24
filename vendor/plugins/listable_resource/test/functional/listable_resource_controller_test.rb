require File.join(File.dirname(__FILE__), '../test_helper')

class ListableResourceControllerTest < Test::Unit::TestCase
  
  fixtures :resources
  
  def setup
    @controller = StubController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    set_listable_resource(:sortable_fields => %w(name city zip))
    setup_custom_routes
  end
  
  def teardown
    teardown_custom_routes
  end
  
  def test_raises_error_if_unlistable_resource_called
    assert_raises DigitalPulp::ListableResource::ListableResourceError do
      StubController.send :listable_resource, :unlistable
    end
  end
  
  def test_does_not_raise_if_listable_resource_called
    assert_nothing_raised do
      StubController.send :listable_resource, :resource
    end
  end
  
  def test_process_sort_should_assign_variable
    StubController.send :listable_resource, :resource
    @controller.stubs(:params).returns({:sort => 'zip', :direction => 'desc'})
    assert_equal "zip desc", @controller.order_and_direction
  end
  
  def test_should_override_model_sortable_fields
    StubController.send :listable_resource, :resource, :sorts => [:name, :zip]
    @controller.stubs(:params).returns({:sort => :city})
    assert_equal "name asc", @controller.order_and_direction
  end
  
  def test_should_sort_on_model_default_if_none_given
    StubController.send :listable_resource, :resource
    @controller.stubs(:params).returns({})
    assert_equal "name asc", @controller.order_and_direction
  end
  
  def test_should_override_model_default
    StubController.send :listable_resource, :resource, :default => :zip
    @controller.stubs(:params).returns({})
    assert_equal 'zip asc', @controller.order_and_direction
  end
  
end