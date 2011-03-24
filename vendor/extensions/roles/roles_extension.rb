require_dependency 'application'

class RolesExtension < Radiant::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/roles"
  
  define_routes do |map|
    map.resources :roles, :path_prefix => 'admin'
  end
  
  def activate
    Role.register(:admin, :developer) rescue nil # hacky hack for bootstrap
    Page.send(:include, Roles::PageExtensions)
    User.send(:include, Roles::UserExtensions)
    Admin::PageController.send(:include, Roles::PageControllerExtensions)
    ApplicationController.send(:include, Roles::ApplicationExtensions)
    admin.page.edit.add :parts_bottom, 'edit_permissions', :after => "edit_layout_and_type"
    admin.tabs.add 'Roles', '/admin/roles', :visibility => :admin
  end
  
  def deactivate
  end
  
end