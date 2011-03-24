class RelateArticlesToFeeds < ActiveRecord::Migration
  def self.up
    add_column :articles, :feed_id, :integer
    remove_column :articles, :content_provider_id
  end

  def self.down
    remove_column :articles, :feed_id, :integer
    add_column :articles, :content_provider_id
  end
end
