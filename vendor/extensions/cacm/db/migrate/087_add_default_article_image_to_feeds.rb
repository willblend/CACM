class AddDefaultArticleImageToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :default_article_image_id, :integer
  end

  def self.down
    remove_column :feeds, :default_article_image_id
  end
end