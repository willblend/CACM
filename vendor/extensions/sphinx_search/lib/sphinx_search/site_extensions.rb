module SphinxSearch
  module SiteExtensions
    
    def self.included(base)
      base.class_eval do
        after_create :set_homepage_site_id
      end
    end
    
    def set_homepage_site_id
      self.homepage.update_attribute(:site_id, id)
    end
    
  end
end