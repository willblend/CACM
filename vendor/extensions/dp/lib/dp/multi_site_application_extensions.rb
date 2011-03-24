module DP
  module MultiSiteApplicationExtensions
    
    def self.included(base)
      [base, *base.descendants].each do |c|
        c.before_filter :set_site_for_page
        c.helper_method :current_site
      end
    end
    
    def current_site
      Site.find_for_host(request.host)
    end

    # THIS IS WHY WE CAN'T HAVE NICE THINGS
    # multi_site only sets the Page.current_site object within the SiteController,
    # so naturally everything falls to pieces when handling a RailsPage
    def set_site_for_page
      Page.current_site = current_site
      true
    end
    
  end
end