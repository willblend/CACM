class Role < ActiveRecord::Base
  has_and_belongs_to_many :users, :join_table => :user_roles
  has_and_belongs_to_many :pages, :join_table => :page_roles
  
  validates_presence_of :name
  
  def after_create
    add_to_user_model
  end
  
  class << self
    # hook for this and other extensions to register new roles
    def register(*roles)
      return unless connection.tables.include?(table_name)
      roles.each do |role|
        role = find_or_create_by_name(role.to_s.titleize)
      end
    end
    
    def all_except_admin
      self.find(:all, :conditions => 'name != "Admin"', :order => 'name ASC')
    end
  end
  
  private
  
    def add_to_user_model(role=self)
      User.class_eval do
        define_method "#{role.name.downcase.gsub(' ','_')}?" do
          roles.include? role
        end
      end
    end
  
  # lastly:  load any roles already defined in
  # the DB since detection methods are dynamic
  if connection.tables.include?(table_name)
    self.find(:all).each do |role|
      role.send :add_to_user_model, role
    end
  end
end
