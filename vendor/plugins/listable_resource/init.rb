ActiveRecord::Base.send(:include, DigitalPulp::ListableResource)
ActionView::Base.send(:include, DigitalPulp::ListableResource::Helper)
ActionController::Base.send(:include, DigitalPulp::ListableResource::ControllerMethods)