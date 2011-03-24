class AddClassNameToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :class_name, :string
    Feed.reset_column_information
    feed = Feed.find(:all)
    feed.each do |f|
      f.class_name = 'RssFeed'
      f.save
    end 
  end
  
  def self.down
    remove_column :feeds, :class_name
  end
  
end