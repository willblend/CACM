# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class SitemapSearchExtension < Radiant::Extension
  version "1.0"
  description "Enables quick finding of pages by title or slug."
  url "http://code.digitalpulp.com"
  
  define_routes do |map|
    map.page_search 'admin/pages/search', :controller => "admin/page", :action => "search"
  end
  
  def activate
    Page.send :include, SitemapSearch::Model
    Admin::PageController.send :include, SitemapSearch::Controller
    admin.page.index.add :top, "sitemap_search"

    # Use the index partials for search page too
    admin.page.status = admin.page.search = admin.page.index
  end
  
  def deactivate
    # admin.tabs.remove "Sitemap Search"
  end
  
end
