module DP
  module CopyMoveExtensions
   
    def self.included(base)
      base.class_eval do
        include Roles::UserPermissionExtensions
        only_allow_access_to :index, :copy_move,
          :when => CACM::FULL_ACCESS_ROLES,
          :denied_url => { :controller => 'admin/page', :action => 'index' },
          :denied_message => 'You are not authorized to edit that page.'
      end
    end
    
  end
end