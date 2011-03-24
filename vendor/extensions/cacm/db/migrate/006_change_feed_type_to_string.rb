class ChangeFeedTypeToString < ActiveRecord::Migration
  def self.up
    change_column :feeds, :feed_type, :string
  end

  def self.down
    change_column :feeds, :feed_type, :integer
  end
end
