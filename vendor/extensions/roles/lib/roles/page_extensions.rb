module Roles
  module PageExtensions
    
    def self.included(base)
      base.class_eval do
        has_and_belongs_to_many :roles, :join_table => :page_roles
      end
    end
    
    def inherited_roles
      [self, *ancestors].inject([]) { |roles,page| roles | page.roles }
    end
    
  end
end