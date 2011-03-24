module Roles
  module UserPermissionExtensions
    
    def user_has_permissions
      return true if current_user.admin? || current_user.developer?
      page = Page.find(params[:id] || params[:parent_id]) # account for .new action
      until page.nil? do
        return true if (page.roles & current_user.roles).any?
        page = page.parent
      end
    end
    
  end
end