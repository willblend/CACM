require 'test/unit'
require 'rubygems'
require 'mocha'

plugin_test_dir = File.dirname(__FILE__)

# Load the Rails environment
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require 'test_help'
require 'active_record/fixtures'
databases = YAML::load(IO.read(plugin_test_dir + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")

# A specific database can be used by setting the DB environment variable
ActiveRecord::Base.establish_connection(databases[ENV['DB'] || 'mysql'])

# Load the test schema into the database
load(File.join(plugin_test_dir, 'schema.rb'))

# Load fixtures from the plugin
Test::Unit::TestCase.fixture_path = File.join(plugin_test_dir, 'fixtures/')

class StubController < ActionController::Base
  def rescue_action(e)
    raise e
  end
  def method_missing(method, *args, &block)
    if (args.size == 0) and not block_given?
      render :text => 'just a test' and return
    else
      super
    end
  end
end

class Resource < ActiveRecord::Base
  has_many :assets
end

class Unlistable < ActiveRecord::Base
end

class Asset < ActiveRecord::Base
  belongs_to :resource
end

def set_listable_resource(options={})
  Resource.class_eval <<-end_eval
    listable_resource(options)
  end_eval
end

def create_resource(options={})
  Resource.create(resource_options(options))
end

def resource_options(options={})
  { :name => 'Test Resource', :city => 'Garden City', :state => 'New York', :zip => '10021' }.merge(options)
end

def setup_custom_routes
  map = ActionController::Routing::RouteSet::Mapper.new(routes)
  map.connect ':controller/:action/:id'
  routes.named_routes.install
end

def teardown_custom_routes
  routes.reload
end

private

  def routes
    ActionController::Routing::Routes
  end