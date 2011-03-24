class AddMobileToArticles < ActiveRecord::Migration
  def self.up
    add_column :articles, :mobile, :boolean, :null=>false, :default=>false
  end

  def self.down
    remove_column :articles, :mobile 
  end
end