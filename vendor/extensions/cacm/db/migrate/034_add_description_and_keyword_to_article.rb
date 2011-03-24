class AddDescriptionAndKeywordToArticle < ActiveRecord::Migration
  def self.up
    add_column :articles, :description, :string
    add_column :articles, :keyword, :string
  end
  
  def self.down
    remove_column :articles, :description
    remove_column :articles, :keyword
  end   
end