require File.join(File.dirname(__FILE__), '/../test_helper')

# require Hit Model
require File.dirname(__FILE__) + '/../../lib/hit'

class Resource < ActiveRecord::Base
  has_many :assets
  
  trackable_resource
end

class Asset < ActiveRecord::Base
  belongs_to :resource
  
  trackable_resource
end

class TrackableResourceTest < Test::Unit::TestCase
  fixtures :resources, :assets
  
  def setup
    
  end
  
  def test_should_create_resource
    assert(resource = create_resource)
    assert_difference resource.hits, :count do
      assert(hit = resource.hits.create(:request => request))
      assert_equal '0.0.0.0', hit.user_ip
    end
  end
  
  def test_should_use_hit_method
    assert(resource = create_resource)
    assert_difference resource.hits, :count do
      assert(hit = resource.track(:request => request))
      assert_equal '0.0.0.0', hit.user_ip
    end
  end
  
  def test_should_return_hits_this_week_month_year
    resource    = create_resource
    resource_2  = create_resource
    asset       = create_asset
    
    5.times do
      resource_2.track :created_at => 3.days.ago
      asset.track :created_at => 3.days.ago
    end
    
    10.times do
      resource.track :created_at => 5.days.ago
    end
    
    10.times do
      resource.track :created_at => 15.days.ago
    end
    
    10.times do
      resource.track :created_at => 200.days.ago
      asset.track :created_at => 200.days.ago
    end
    
    
    assert_equal 10, resource.hits.this_week
    assert_equal 20, resource.hits.this_month
    assert_equal 30, resource.hits.this_year
    
    assert_equal 5, resource_2.hits.this_week
    assert_equal 5, resource_2.hits.this_month
    assert_equal 5, resource_2.hits.this_year
    
    assert_equal 5, asset.hits.this_week
    assert_equal 5, asset.hits.this_month
    assert_equal 15, asset.hits.this_year
  end
  
  def test_should_return_unique_hits_this_week_month_year
    resource    = create_resource
    resource_2  = create_resource
    asset       = create_asset
    
    ['127.0.0.1', '127.0.1.1'].each do |ip|
      5.times do
        resource_2.track :created_at => 3.days.ago, :user_ip => ip
        asset.track :created_at => 3.days.ago, :user_ip => ip
      end
    end
    
    ['127.0.0.1', '127.0.1.1'].each do |ip|
      10.times do
        resource.track :created_at => 5.days.ago, :user_ip => ip
      end
    end
    
    ['127.0.0.1', '127.0.1.1'].each do |ip|
      10.times do
        resource.track :created_at => 15.days.ago, :user_ip => ip
      end
    end
    ['127.0.0.1', '127.0.1.1'].each do |ip|
      10.times do
        resource.track :created_at => 200.days.ago, :user_ip => ip
        asset.track :created_at => 200.days.ago, :user_ip => ip
      end
    end
    
    assert_equal 2, resource.hits.this_week(true)
    assert_equal 4, resource.hits.this_month(true)
    assert_equal 6, resource.hits.this_year(true)
    
    assert_equal 2, resource_2.hits.this_week(true)
    assert_equal 2, resource_2.hits.this_month(true)
    assert_equal 2, resource_2.hits.this_year(true)
    
    assert_equal 2, asset.hits.this_week(true)
    assert_equal 2, asset.hits.this_month(true)
    assert_equal 4, asset.hits.this_year(true)
  end
  
  private
  
  def request
    ActionController::TestRequest.new
  end
  
  def create_resource(options={})
    Resource.create(resource_options(options))
  end
  
  def resource_options(options={})
    { :name => 'Test Resouce', :city => 'Garden City', :state => 'New York', :zip => '10021' }.merge(options)
  end
  
  def create_asset(options={})
    Asset.create(asset_options(options))
  end

  def asset_options(options={})
    { :resource_id => 1, :name => 'Test Asset'}.merge(options)
  end
  
end