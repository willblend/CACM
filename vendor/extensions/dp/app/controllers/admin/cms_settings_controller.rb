class Admin::CmsSettingsController < ApplicationController
  only_allow_access_to :index, :edit, :update, :create, :destroy, :show, :when => CACM::ADMIN_ACCESS_ROLES,
    :denied_url => { :controller => 'admin/page', :action => 'index' },
    :denied_message => 'You are not authorized to view that page.'
end