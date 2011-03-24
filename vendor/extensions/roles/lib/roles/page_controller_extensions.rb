module Roles
  module PageControllerExtensions
    
    def self.included(base)
      base.class_eval do
        before_filter :sanitize_roles
        only_allow_access_to :new, :edit, :remove,
          :when => CACM::FULL_ACCESS_ROLES,
          :denied_url => {:controller => 'page', :action => 'index'},
          :denied_message => 'You are not authorized to edit that page.'
      end
    end

    def user_has_permissions
      return true if current_user.admin? || current_user.developer?
      page = Page.find(params[:id] || params[:parent_id]) # account for .new action
      until page.nil? do
        return true if (page.roles & current_user.roles).any?
        page = page.parent
      end
    end

    def sanitize_roles
      params[:page].delete(:role_ids) if params[:page] && !current_user.admin?
    end
    
  end
end