class SetClassOnCacmArticles < ActiveRecord::Migration
  def self.up
    ThinkingSphinx.deltas_enabled = false
    DLArticle.find(:all).each do |article|
      article.update_attribute(:class_name, 'CacmArticle')
    end
  end
  
  def self.down
  end
end