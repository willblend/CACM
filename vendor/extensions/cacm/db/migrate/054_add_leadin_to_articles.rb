class AddLeadinToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :leadin, :text
    change_column :articles, :toc, :text
  end
  
  def self.down
    remove_column :articles, :leadin
    change_column :articles, :toc, :string
  end
end