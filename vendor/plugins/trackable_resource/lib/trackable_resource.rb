module DigitalPulp
  module ActiveRecord
    module Extensions
      module TrackableResource
        
        def self.included(base)
          base.extend ClassMethods
        end
        
        module ClassMethods
          def trackable_resource(options={})
            options = {
              :unique_hits => false
            }.merge(options)
            
            has_many :hits, :as => :trackable do
              
              def this_week(unique=false)                
                find_by_time(7.days.ago, unique)
              end
              
              def this_month(unique=false)
                find_by_time(1.month.ago, unique)
              end
              
              def this_year(unique=false)
                find_by_time(1.year.ago, unique)
              end
              
              def find_by_time(time, unique=false)
                 unless unique
                    count(:conditions => "created_at > '#{time.to_s(:db)}'")
                  else
                    count( :all,
                           :select => "DISTINCT(CONCAT(user_ip, ' ', substr(created_at, 1, 10)))",
                          :conditions => "created_at > '#{time.to_s(:db)}'")
                  end
              end
            end
            
            unless self.included_modules.include?(DigitalPulp::ActiveRecord::Extensions::TrackableResource::InstanceMethods)
              include DigitalPulp::ActiveRecord::Extensions::TrackableResource::InstanceMethods
              extend DigitalPulp::ActiveRecord::Extensions::TrackableResource::SingletonMethods
            end
            
          end
        end
        
        module SingletonMethods
          
        end
        
        module InstanceMethods
          def track(*args)
            self.hits.create(*args)
          end
        end
        
      end
    end
  end
end