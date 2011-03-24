class AddArticleBrandings < ActiveRecord::Migration
  def self.up
    add_column :articles, :top_branding, :text
    add_column :articles, :bottom_branding, :text
  end
  
  def self.down
    remove_column :articles, :top_branding
    remove_column :articles, :bottom_branding
  end
end