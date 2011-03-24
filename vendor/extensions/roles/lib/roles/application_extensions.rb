module Roles
  module ApplicationExtensions

    def self.included(base)
      base.send :helper_method, :restrict_to
    end

    def restrict_to(*roles, &block)
      yield if current_user.admin? || (current_user.roles & Role.find_all_by_name(roles.flatten.map{|x| x.to_s.gsub('_',' ')})).any?
    end

  end
end