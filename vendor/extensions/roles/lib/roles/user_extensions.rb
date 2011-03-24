module Roles
  module UserExtensions
    
    def self.included(base)
      base.class_eval do
        has_and_belongs_to_many :roles, :join_table => :user_roles
      
        %w(admin developer).each do |role|
          define_method "#{role}?" do
            self.roles.map{|r| r.name.downcase}.include?(role)
          end
        end
        
      end
    end
    
  end
end