class AddClassnameIndexToArticles < ActiveRecord::Migration
  def self.up
    add_index :articles, [:class_name, :uuid]
  end
  
  def self.down
    remove_index :articles, [:class_name, :uuid]
  end
end