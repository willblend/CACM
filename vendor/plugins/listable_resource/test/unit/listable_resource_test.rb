require File.join(File.dirname(__FILE__), '../test_helper')

class ListableResourceTest < Test::Unit::TestCase
  fixtures :resources, :assets
  
  def setup
    set_listable_resource
  end
  
  def test_should_find_all_resources
    assert Resource.find(:all).size > 0
    assert Resource.find_all.size > 0
  end
  
  def test_should_perform_normal_find_with_conditions
    resources = Resource.find(:all, :conditions => "name = 'Resource 1'")
    assert !resources.empty?
  end
  
  def test_should_perform_dynamic_find    
    resources = Resource.find_all_by_name('Resource 1')
    assert !resources.empty?
  end
  
  def test_should_perform_normal_find_with_pagination
    resources = Resource.paginate(:all, :page => 1)
    assert !resources.empty?
  end
  
  def test_should_perform_dynamic_find_with_pagination
    resources = Resource.paginate_all_by_name('Resource 1', :page => 1)
    assert !resources.empty?
  end
  
  # BEGIN::Search Testing
  
  def test_should_find_resources_with_search_term
    resources = Resource.find(:all, :search => 'Resource')
    assert !resources.empty?
    resources.each do |resource|
      assert_match( /resource/i, resource.name)
    end
  end
  
  def test_should_find_resources_with_search_term_and_pagination
    resources = Resource.paginate(:all, :page => 1, :search => 'Resource')
    assert !resources.empty?
    resources.each do |resource|
      assert_match( /resource/i, resource.name)
    end
  end
  
  def test_should_search_associated_asset_name
    set_listable_resource :searchable_fields => %w( resources.name assets.name )
    
    resources = Resource.find(:all, :search => 'Asset', :conditions => [" assets.id = ? ", 1], :include => [:assets] )
    assert !resources.empty?
    resources.each do |resource|
      resource.assets.each do |asset|
          assert_match( /asset/i, asset.name)
      end
    end 
  end
  
  def test_should_split_search_terms
    Resource.destroy_all
    3.times { create_resource }
    create_resource :name => 'not in search results', :city => 'not in search results'
    resources = Resource.find(:all, :search => 'Test Garden')

    assert_equal 3, resources.size
  end
  
  def test_should_not_remove_extra_characters
    Resource.destroy_all
    3.times { create_resource :city => "Garden@city.com" }
    create_resource :name => 'not in search results', :city => 'not in search results'
    resources = Resource.find(:all, :search => 'Garden@city.com')

    assert_equal 3, resources.size
  end
  
  def test_should_not_split_search_with_quotes
    Resource.destroy_all
    3.times { create_resource }
    create_resource :name => 'not in search results', :city => 'not in search results'
    
    resources = Resource.find(:all, :search => '"Test Garden"')
    assert_equal 0, resources.size
    
    resources = Resource.find(:all, :search => '"Garden City"')
    assert_equal 3, resources.size
    
  end
  
  # END::Search Testing
  
  # BEGIN::Index Testing
  
  def test_should_not_index_by_default
    assert_raise DigitalPulp::ListableResource::ListableResourceError do
      Resource.find(:all, :index => 'Resource')
    end
  end
  
  def test_should_index_on_name_when_defined
    set_listable_resource :index_search_field => 'name'
    
    resources = Resource.find(:all, :index => 'r')
    resources.each do |resource|
      assert_match( /^r/i, resource.name)
    end
  end
  
  def test_should_handle_case_where_index_doesnt_match
    set_listable_resource :index_search_field => 'name'
    
    resources = Resource.find(:all, :index => '%')
    assert_equal resources, Resource.find(:all)
  end
  
  def test_should_index_on_city_when_defined
    set_listable_resource :index_search_field => 'city'
    
    resources = Resource.find(:all, :index => 'n')
    resources.each do |resource|
      assert_match( /^n/i, resource.city)
    end
  end
  
  # END::Index Testing
  
  # BEGIN::Filter Testing
  
  def test_should_not_filter_by_default
    assert_raise DigitalPulp::ListableResource::ListableResourceError do
      Resource.find(:all, :filter => 'Resource')
    end
  end
  
  def test_should_filter_on_name_when_defined
    set_listable_resource :filter_field => 'city'
    
    resources = Resource.find(:all, :filter => 'New York')
    resources.each do |resource|
      assert_equal 'New York', resource.city
    end
  end
  
  def test_should_filter_on_state_when_defined
    set_listable_resource :filter_field => 'state'
    
    resources = Resource.find(:all, :filter => 'New York')
    resources.each do |resource|
      assert_equal 'New York', resource.state
    end
  end
  
  # END::Filter Testing
  
  # BEGIN::Order Testing
  
  def test_should_set_order_method_to_reverse_direction
    resources = Resource.find(:all, :order => 'name asc')
    
    assert_equal 'name desc', Resource.order_for('name')
    assert_equal 'city asc', Resource.order_for('city')
    assert_equal 'state asc', Resource.order_for('state')
    assert_equal 'zip asc', Resource.order_for('zip')
    
    resources = Resource.find(:all, :order => 'name desc')
    
    assert_equal 'name asc', Resource.order_for('name')
    assert_equal 'city asc', Resource.order_for('city')
    assert_equal 'state asc', Resource.order_for('state')
    assert_equal 'zip asc', Resource.order_for('zip')
    
    resources = Resource.find(:all, :order => 'city asc')
    
    assert_equal 'name asc', Resource.order_for('name')
    assert_equal 'city desc', Resource.order_for('city')
    assert_equal 'state asc', Resource.order_for('state')
    assert_equal 'zip asc', Resource.order_for('zip')
    
    resources = Resource.find(:all, :order => 'city desc')
    
    assert_equal 'name asc', Resource.order_for('name')
    assert_equal 'city asc', Resource.order_for('city')
    assert_equal 'state asc', Resource.order_for('state')
    assert_equal 'zip asc', Resource.order_for('zip')
  end
  
  def test_should_sort_by_fields_asc
    
    %w( name city state zip ).each do |field|
      Resource.destroy_all

      %w( Bresource Dresource Aresource Cresource ).each do |value|
        create_resource field.intern => value
      end
      
      resources = Resource.find(:all, :order => field + ' asc')
      assert_equal ['Aresource', 'Bresource', 'Cresource', 'Dresource'], resources.map(&field.intern)
      
    end

  end
  
  def test_should_sort_by_fields_desc
    
    %w( name city state zip ).each do |field|
      Resource.destroy_all

      %w( Bresource Dresource Aresource Cresource ).each do |value|
        create_resource field.intern => value
      end
      
      resources = Resource.find(:all, :order => field + ' desc')
      assert_equal ['Dresource', 'Cresource', 'Bresource', 'Aresource'], resources.map(&field.intern)
      
    end

  end
  
  # END::Order Testing
  
  
  def test_should_search_and_filter
    set_listable_resource :filter_field => 'state',
                          :searchable_fields => %w( name )
    
    resources = Resource.find(:all, :filter => 'New York', :search => '1')
    resources.each do |resource|
      assert_equal 'New York', resource.state
      assert_match(/1/, resource.name)
    end
  end
  
  def test_should_search_and_filter_with_pagination
    set_listable_resource :filter_field => 'state',
                          :searchable_fields => %w( name )
    
    resources = Resource.paginate(:all, :page => 1, :filter => 'New York', :search => '1')
    resources.each do |resource|
      assert_equal 'New York', resource.state
      assert_match(/1/, resource.name)
    end
  end
  
  def test_should_return_index_search_field
    set_listable_resource :index_search_field => 'state',
                          :searchable_fields => %w( name )
    resource = resources(:one)
    assert 'state', resource.index_search_field
  end
  
  def test_should_match_index_letter
    set_listable_resource :index_search_field => 'state',
                          :searchable_fields => %w( name )
    resource = resources(:one)
    
    assert 'state', resource.index_search_field
    
    resource.state = "NY"
    assert resource.matches_index('n')
    assert !resource.matches_index('a')
  end
  
  def test_should_match_index_letter_case_sensitive
    set_listable_resource :index_search_field => 'state',
                          :searchable_fields => %w( name )
    resource = resources(:one)
    
    assert 'state', resource.index_search_field
    
    resource.state = "NY"
    assert resource.matches_index('N', true)
    assert !resource.matches_index('n', true)
    assert !resource.matches_index('a')
  end
  
  def test_should_return_active_indexes
    set_listable_resource :index_search_field => 'state',
                          :searchable_fields => %w( name )
    
    resources = Resource.find(:all)
    
    assert_equal ['n', 't'], Resource.active_indexes(resources)
  end
  
  def test_should_return_active_indexes_case_sensitive
    set_listable_resource :index_search_field => 'state',
                          :searchable_fields => %w( name )
    
    resources = Resource.find(:all)
    
    assert_equal ['N', 'T'], Resource.active_indexes(resources, true)
  end
  
  def test_should_return_active_indexes_using_find
    set_listable_resource :index_search_field => 'city',
                          :searchable_fields => %w( name )
                          
    resources = Resource.find(:all, :conditions => "state = 'New York'")
    
    assert_equal ['b', 'g', 'n'], Resource.find_active_indexes(:conditions => "state = 'New York'").sort
    assert_equal ['b', 'd', 'g', 'n'], Resource.find_active_indexes.sort
  end
  
  def test_should_raise_error_if_active_index_not_defined
    assert_raise DigitalPulp::ListableResource::ListableResourceError do
      Resource.find_active_indexes
    end
  end
  
end
