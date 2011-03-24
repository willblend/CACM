module ArticleExtensions
  def self.included(base)
    base.class_eval {
      def self.featured
        self.find(:all, :conditions=>['featured_article = ?', true])
      end

      def self.remove_first_featured
        count = self.featured.count 
        if count == 0 
          puts "Nothing to remove" 
        else 
         puts "Removing one of #{count}"
         self.featured.first.update_attribute(:featured_article, false)
        end
      end
    }
  end
end
