module CACM
  module PageExtensions
    
    # Make session object available to Radiant pages
    def self.included(base)
      base.class_eval do
        attr_accessor :current_member
      end
    end
    
  end
end