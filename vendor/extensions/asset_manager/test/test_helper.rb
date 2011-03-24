require 'test/unit'
require 'rubygems'
require 'mocha'
# # Load the environment
unless defined? RADIANT_ROOT
  ENV["RAILS_ENV"] = "test"
  require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/environment"
end
require "#{RADIANT_ROOT}/test/test_helper"

class Test::Unit::TestCase
  
  # Include a helper to make testing Radius tags easier
  test_helper :extension_tags
  # include JamisBuck::Routing::TestHelper
  
  # Add the fixture directory to the fixture path
  self.fixture_path << File.dirname(__FILE__) + "/fixtures"
  
  # Add more helper methods to be used by all extension tests here...
    def assert_included(collection, item)
      assert_block "#{collection} was expected to include #{item} but does not." do
        collection.include?(item)
      end
    end
    
    def assert_not_included(collection, item)
      assert_block "#{collection} was not expected to include #{item}." do
        !collection.include?(item)
      end
    end
    
    def assert_not_empty(collection)
      assert_block "#{collection} was not expected to be empty but was empty." do
        !collection.empty?
      end
    end
    
    def assert_empty(collection)
      assert_block "#{collection} was expected to be empty but was not empty." do
        collection.empty?
      end
    end
    
    def file_upload(filename, content_type)
      path = File.dirname(__FILE__) + "/fixtures/" + filename
      ActionController::TestUploadedFile.new(path, content_type)
    end
end

class User
  # this got lost somewhere?
  def self.sha1(phrase)
    Digest::SHA1.hexdigest("--test-salt--#{phrase}--")
  end
end

class ActionController::TestSession
  def session_name
    '_test_session'
  end
end