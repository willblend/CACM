class AddIndexes < ActiveRecord::Migration
  def self.up
    add_index :assets, :filename
    add_index :assets, :description
    add_index :assets, :content_type
  end
  
  def self.down
    remove_index :assets, :filename
    remove_index :assets, :description
    remove_index :assets, :content_type
  end
end
