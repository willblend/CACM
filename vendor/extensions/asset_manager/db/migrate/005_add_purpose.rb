class AddPurpose < ActiveRecord::Migration
  def self.up
    add_column :assets, :purpose, :string
  end
  
  def self.down
    remove_column :assets, :purpose
  end
end