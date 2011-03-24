class AddFileUpdatedAt < ActiveRecord::Migration
  def self.up
    add_column :assets, :file_updated_at, :timestamp
  end
  
  def self.down
    remove_column :assets, :file_updated_at
  end
end