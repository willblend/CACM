# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'
require 'status'
class WorkflowExtension < Radiant::Extension
  version "0.3"
  description "Enables Draft/Review/Publish workflow with working copies."
  url "http://code.digitalpulp.com"
  
  define_routes do |map|
    map.with_options :controller => "workflow" do |page|
      page.update_status "admin/pages/update_status/:id", :action => "update_status"
      page.revert "admin/pages/revert/:id", :action => "revert"
      page.publish "admin/pages/publish/:id", :action => "publish"
      page.publish_tree "admin/pages/publish_tree/:id", :action => "publish_tree"
      page.draft_tree "admin/pages/draft_tree/:id", :action => "draft_tree"
    end
  end
  
  def activate
    require 'recursive_collect'
    Page.class_eval do
      include Workflow::Drafts
      include Workflow::PublishTree
    end

    Admin::PageController.send :include, Workflow::PageControllerExtensions
    Status[:reviewed].name = "Review" if Status[:reviewed]

    admin.page.edit.add :buttons, 'publish_button'

    admin.page.index.add :bottom, 'workflow_scripts'
    admin.page.index.add :sitemap_head, 'workflow_extra_th', :before => "preview"
    admin.page.index.add :node, 'workflow_extra_td', :before => "preview_links_column"
  end
end
