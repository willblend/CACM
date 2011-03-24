class RemoveExtraColumns < ActiveRecord::Migration
  def self.up
    remove_column :articles, :pages
    remove_column :articles, :section_type
    remove_column :articles, :section_title
  end
  
  def self.down
    add_column :articles, :pages, :string
    add_column :articles, :section_type, :string
    add_column :articles, :section_title, :string
  end   
end