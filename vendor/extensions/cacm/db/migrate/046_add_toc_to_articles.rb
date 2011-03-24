class AddTocToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :toc, :string
  end
  
  def self.down
    remove_column :issues, :toc
  end   
end