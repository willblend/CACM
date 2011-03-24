class AddCountsToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :email_count, :integer
    add_column :articles, :view_count, :integer
  end
  
  def self.down
    remove_column :articles, :view_count
    remove_column :articles, :email_count
  end   
end