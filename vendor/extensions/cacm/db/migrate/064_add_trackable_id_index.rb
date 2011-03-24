class AddTrackableIdIndex < ActiveRecord::Migration
  def self.up
    execute "TRUNCATE TABLE `hits`"
    add_index :hits, :trackable_id
  end
  
  def self.down
    remove_index :hits, :trackable_id
  end
end