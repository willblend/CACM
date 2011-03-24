class AddActiveStateToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :active, :boolean, :default => true
  end
  
  def self.down
    remove_column :feeds, :active
  end
end