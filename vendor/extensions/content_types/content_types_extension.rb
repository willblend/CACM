require_dependency 'application'

class ContentTypesExtension < Radiant::Extension
  version "1.0"
  description "Imposes structure on pages via content types."
  url "http://code.digitalpulp.com/"
  
  define_routes do |map|
    map.resources :content_types, :path_prefix => "/admin", 
        :member => { :move_higher => :post, :move_lower => :post, 
                     :move_to_top => :post, :move_to_bottom => :post}
  end
  
  def activate
    Page.class_eval do
      include ContentTypes::Associations
      include ContentTypes::Tags
    end
    Admin::PageController.class_eval do
      include ContentTypes::ControllerExtensions
      helper ContentTypes::Helper
    end
    admin.tabs.add "Content Types", "/admin/content_types", :before => "Layouts", :visibility => [:developer, :admin]
    # Admin UI customization
    admin.page.edit.add :form, 'edit_content_type', :before => 'edit_page_parts'
    admin.page.edit.form.delete 'edit_page_parts'
    admin.page.index.add :bottom, 'index_add_child_popup'
    admin.page.index.add :node, 'type_column', :before => 'status_column'
    admin.page.index.add :sitemap_head, 'type_column_header', :before => 'status_column_header'
  end
  
  def deactivate
    admin.tabs.remove "Content Types"
  end
  
end


