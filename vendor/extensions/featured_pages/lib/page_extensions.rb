module PageExtensions
  def self.included(base)
    base.class_eval {
      def self.featured
        self.find(:all, :conditions => {:featured_page => true})
      end
      def self.remove_first_featured
        self.find.featured.update_attribute :featured_article, false 
      end
    }
  end
end