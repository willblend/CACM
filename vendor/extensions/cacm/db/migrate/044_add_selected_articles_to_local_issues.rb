class AddSelectedArticlesToLocalIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :selected_article_ids, :string
  end
  
  def self.down
    remove_column :issues, :selected_article_ids
  end   
end