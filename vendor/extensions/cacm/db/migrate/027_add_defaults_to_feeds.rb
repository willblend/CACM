class AddDefaultsToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :news_opinion, :boolean
    add_column :feeds, :digital_library, :boolean
    add_column :feeds, :acm_resource, :boolean
    add_column :feeds, :user_comments, :boolean
    
    remove_column :feeds_sections, :id
    remove_column :feeds_topics, :id
    remove_column :articles_sections, :id
  end
  
  def self.down
    remove_column :feeds, :news_opinion, :boolean
    remove_column :feeds, :digital_library, :boolean
    remove_column :feeds, :acm_resource, :boolean
    remove_column :feeds, :user_comments, :boolean
  end
end