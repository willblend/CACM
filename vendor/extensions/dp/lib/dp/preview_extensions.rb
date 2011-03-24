module DP
  module PreviewExtensions
    
    def self.included(base)
      base.instance_eval do
        def full_url
          page = is_draft? ? draft_parent : self
          page.root.site.url(page.url)
        end
      end
    end
     
  end
end