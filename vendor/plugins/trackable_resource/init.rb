require 'trackable_resource'
ActiveRecord::Base.send(:include, DigitalPulp::ActiveRecord::Extensions::TrackableResource)

require 'trackable_resource_controller'
ActionController::Base.send(:include, DigitalPulp::ActionController::Extensions::TrackableResource)

