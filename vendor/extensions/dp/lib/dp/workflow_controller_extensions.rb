module DP
  module WorkflowControllerExtensions

    def self.included(base)
      base.class_eval do
        include Roles::UserPermissionExtensions # provides cascaded permissions lookup
        only_allow_access_to :revert, :publish, :publish_tree, :draft_tree, :update_status,
          :when => CACM::FULL_ACCESS_ROLES,
          :denied_url => { :controller => 'admin/page', :action => 'index' },
          :denied_message => 'You are not authorized to edit that page.'
        append_before_filter :check_status_permissions
      end
    end


    def check_status_permissions
      return true if current_user.admin? or current_user.content_editors?

      allowed_states = [Status[:draft], Status[:review]]
      page = Page.find(params[:id])
      page = page.draft || page

      case action_name
      when /revert/ # editors can revert a draft
        return true
      when /update_status/ # editors can toggle between draft and review, but not published
        access_denied and return unless allowed_states.include?(page.status) and allowed_states.include?(Status.find(params[:status_id].to_i))
      else # tree mods are disallowed
        access_denied and return
      end
    end
    
    def access_denied
      flash[:error] = 'You are not authorized to perform that action.'
      redirect_to page_index_path
    end
    
  end
end