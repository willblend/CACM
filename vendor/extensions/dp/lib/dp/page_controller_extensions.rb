module DP
  module PageControllerExtensions
    
    def self.included(base)
      base.class_eval do
        alias_method_chain :continue_url, :draft
      end
    end
    
    # WORKFLOW/MULTISITE INTEGRATION
    def continue_url_with_draft(options={})
      page = (@page.draft_parent || @page)
      if page.parent
        page_index_url(:root => page.parent)
      elsif page.site
        page_index_url(:root => page)
      else
        continue_url_without_draft(options)
      end
    end
    
  end
end