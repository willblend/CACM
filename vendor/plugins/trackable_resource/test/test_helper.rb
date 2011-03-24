require 'test/unit'

plugin_test_dir = File.dirname(__FILE__)

# Load the Rails environment
require File.expand_path(File.dirname(__FILE__) + "/../../../../config/environment")
require 'active_record/fixtures'
databases = YAML::load(IO.read(plugin_test_dir + '/database.yml'))
ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/debug.log")

# A specific database can be used by setting the DB environment variable
ActiveRecord::Base.establish_connection(databases[ENV['DB'] || 'mysql'])

# Load the test schema into the database
load(File.join(plugin_test_dir, 'schema.rb'))

# Load fixtures from the plugin
Test::Unit::TestCase.fixture_path = File.join(plugin_test_dir, 'fixtures/')

require File.dirname(__FILE__) + '/abstract_unit'

class Test::Unit::TestCase
  
  def assert_difference(object, method = nil, difference = 1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method), "#{object}##{method}"
  end
  
  def assert_no_difference(object, method, &block)
    assert_difference object, method, 0, &block
  end
  
end