class AddFeedIdAndStateIndex < ActiveRecord::Migration
  def self.up
    add_index :articles, [:feed_id, :state]
  end
  
  def self.down
    remove_index :articles, [:feed_id, :state]
  end
end