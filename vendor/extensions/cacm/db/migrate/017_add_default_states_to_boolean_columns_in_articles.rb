class AddDefaultStatesToBooleanColumnsInArticles < ActiveRecord::Migration
  def self.up
    change_column :articles, :user_comments, :boolean, :default => false
    change_column :articles, :news_opinion, :boolean, :default => false
    change_column :articles, :digital_library, :boolean, :default => false
    change_column :articles, :acm_resource, :boolean, :default => false
  end
  
  def self.down

  end
end
