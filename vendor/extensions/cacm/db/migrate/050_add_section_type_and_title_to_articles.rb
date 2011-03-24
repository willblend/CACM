class AddSectionTypeAndTitleToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :section_type, :string
    add_column :articles, :section_title, :string
  end
  
  def self.down
    remove_column :articles, :section_type
    remove_column :articles, :section_title
  end   
end