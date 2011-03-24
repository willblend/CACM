class AddTypesToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :feed_type, :integer
    add_column :feeds, :last_ingest, :timestamp
  end

  def self.down
    remove_column :feeds, :feed_type
    remove_column :feeds, :last_ingest
  end
end
