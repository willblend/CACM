class CreateFeaturedArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :featured_article, :boolean, :default => false
    Article.reset_column_information
    Article.update_all(['featured_article = ?',false])
  end

  def self.down
    remove_column :articles, :featured_article
  end
end
