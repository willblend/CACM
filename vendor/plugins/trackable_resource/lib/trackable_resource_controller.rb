module DigitalPulp
  module ActionController
    module Extensions
      module TrackableResource
        
        class TrackableResourceControllerError < StandardError; end
        
        def self.included(base)
          base.extend ClassMethods
        end
        
        module ClassMethods
          def trackable_resource(resource, options={})
            options = {
              :trackable_method_prefix => 'track_'
            }.merge(options)
            
            # def track_resource; end
            define_method("#{options[:trackable_method_prefix]}#{resource}") do
              
              record = options[:find].nil?? resource_name_to_constant(resource).find(params[:id]) : eval(options[:find])
              raise TrackableResourceControllerError.new( "#{resource_name_to_constant(resource)} must define trackable_resource." ) unless record.respond_to?(:track)
              
              hit = record.track(:request => request)
              instance_variable_set("@hit", hit)
              instance_variable_set("@#{resource}", record)
              
              head(204)
            end
            
            unless self.included_modules.include?(DigitalPulp::ActionController::Extensions::TrackableResource::InstanceMethods)
              include DigitalPulp::ActionController::Extensions::TrackableResource::InstanceMethods
              extend  DigitalPulp::ActionController::Extensions::TrackableResource::SingletonMethods
            end
            
          end
        end
        
        module SingletonMethods
          
        end
        
        module InstanceMethods
          
          # Helper method to convert a resource name into a constant
          def resource_name_to_constant(record_name)
            record_name.to_s.classify.constantize
          end
          
        end
        
      end
    end
  end
end