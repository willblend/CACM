unless defined? RADIANT_ROOT
  ENV["RAILS_ENV"] = "test"
  case
  when ENV["RADIANT_ENV_FILE"]
    require ENV["RADIANT_ENV_FILE"]
  when File.dirname(__FILE__) =~ %r{vendor/radiant/vendor/extensions}
    require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../../../")}/config/environment"
  else
    require "#{File.expand_path(File.dirname(__FILE__) + "/../../../../")}/config/environment"
  end
end
require "#{RADIANT_ROOT}/spec/spec_helper"

if File.directory?(File.dirname(__FILE__) + "/scenarios")
  Scenario.load_paths.unshift File.dirname(__FILE__) + "/scenarios"
end
if File.directory?(File.dirname(__FILE__) + "/matchers")
  Dir[File.dirname(__FILE__) + "/matchers/*.rb"].each {|file| require file }
end

Spec::Runner.configure do |config|
  # config.use_transactional_fixtures = true
  # config.use_instantiated_fixtures  = false
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures'

  # You can declare fixtures for each behaviour like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  #   config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
end

require 'ostruct'

class StubCursor < OpenStruct
  def bind_param(*args)
    true
  end
  
  def exec
    false
  end

  def []=(attr,val)
    send("#{attr}=", val)
  end
  
  def [](attr)
    send(attr)
  end
  
  def parse(*anything)
    self
  end
end

class Mysql
  def parse(*args)
    StubCursor.new
  end
end

require 'generator'
IDGEN = Generator.new(1..1000000) # IDGEN.next for uniq ids

class DLArticle
  # stub out some trickier Oracle junk
  %w(map_subjects fetch_dl_data).each do |method|
    define_method method do |*args|
      nil
    end
  end
end

class ArticleSweeper < ActionController::Caching::Sweeper
  # dirty hack, see article_sweeper_spec for details
  def expire_record_with_specs (record)
    true
  end
  alias_method_chain :expire_record, :specs
end

class Oracle::Session
  attr_accessor :ip
end

module DP
  module Spec

    def fake_form_post(unescaped)
      if unescaped.is_a? Hash

        returning Hash.new do |escape|
          unescaped.each_pair do |k,v|
            escape["#{k}"] = "#{v}"
          end
        end

      else
        raise "not ready yet"
      end
    end

  end
end

include DP::Spec
