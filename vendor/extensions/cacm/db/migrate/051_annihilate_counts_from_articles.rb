class AnnihilateCountsFromArticles < ActiveRecord::Migration
  def self.up
    remove_column :articles, :view_count
    remove_column :articles, :email_count
  end
  
  def self.down
    add_column :articles, :email_count, :integer
    add_column :articles, :view_count, :integer
  end   
end