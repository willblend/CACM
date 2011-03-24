class DpExtension < Radiant::Extension
  version "0.17"
  description "Digital Pulp Core Radiant Extensions"
  url "http://digitalpulp.com"
  
  define_routes do |map|
    map.namespace :admin do |admin|
      admin.with_options( :name_prefix => 'admin_', :path_prefix => '/admin' ) do |admin|
        admin.resources :cms_settings
      end
    end

    map.formatted_page_picker 'admin/picker/page.:format', :controller => 'admin/page_picker', :action => 'index', :class => 'pages'
    map.page_picker 'admin/picker/page.fck', :controller => 'admin/page_picker', :action => 'index', :class => 'pages'
  end

  def activate
    Radiant::Config['local.timezone'] = "Eastern Time (US & Canada)"

    require "dp/recursive_collect"

    PageContext.send            :include, DP::ForceErrors

    ApplicationController.send  :include, DP::FrontEndExtensions

    Page.send                   :include, DP::RadiusExtensions,
                                          DP::RadiusTags,
                                          DP::PageExtensions

    Array.send                  :include, DP::ArrayExtensions

    if defined? MultiSiteExtension
      ApplicationController.send  :include, DP::MultiSiteApplicationExtensions
      Radiant::Config['multi_site.scoped?'] = true
    end

    if defined? ContentTypesExtension
      # allow "picker" functionality hooked in via mime types to be served up as HTML
      Mime::Type.register_alias 'text/html', :fck unless defined? :fck # FCK context
      Mime::Type.register_alias 'text/html', :rad unless defined? :rad # Radiant context
    end

    if defined?(WorkflowExtension) && defined?(RolesExtension)
      WorkflowController.send     :include, DP::WorkflowControllerExtensions
    end

    ### FIXME: commenting this out until it's fixed
    # if defined?(ContentTypesExtension) && defined?(WorkflowExtension)
    #   Page.send                   :include, DP::DraftExtensions
    # end

    if defined?(MultiSiteExtension) && defined?(WorkflowExtension)
      Admin::PageController.send  :include, DP::PageControllerExtensions
    end

    if defined?(CopyMoveExtension) && defined?(RolesExtension)
      CopyMoveController.send     :include, DP::CopyMoveExtensions
    end
    
    if defined?(WorkflowExtension) && defined?(PagePreviewExtension)
      Page.send                   :include, DP::PreviewExtensions
    end

    Admin::PageController.class_eval{ helper :dp_node }
    ApplicationController.class_eval{ helper :dp_application }

    # Page Subclasses
    UncachedPage

    # set up tabs
    admin.tabs.remove "Snippets" 
    admin.tabs.remove "Layouts" 
    admin.tabs.remove "Content Types"

    admin.tabs.add "CMS Settings", "/admin/cms_settings", :visibility => [ :admin, :developer ] 

    # add in our breadcrumb and nav fixes
    admin.page.index.add :top, "breadcrumb"
    admin.page.index.add :top, "scoped_navigation"

  end

end