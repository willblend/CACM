class PopulateOracleIds < ActiveRecord::Migration
  def self.up
    ThinkingSphinx.deltas_enabled = false
    DLArticle.find(:all).each do |article|
      article.update_attribute(:oracle_id, article.doi)
    end
  end
  
  def self.down
  end
end