module SitemapSearch::Model
  def self.included(base)
    base.instance_eval do
      def site_map_search(options={})
                    
        @results = Page.search options[:query], :page => options[:page], 
                                                :per_page => options[:per_page]
                                                
                                                
      end
      
    end  
  end
end