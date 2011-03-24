class ChangeFeedTypeBackToInt < ActiveRecord::Migration
  def self.up
    change_column :feeds, :feed_type, :integer
    rename_column  :feeds, :feed_type, :feed_type_id
  end

  def self.down
    rename_column :feeds, :feed_type_id, :feed_type
    change_column :feeds, :feed_type, :string
  end
end
