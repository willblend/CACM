class PopulateArticleClasses < ActiveRecord::Migration
  def self.up
    RssFeed.find(:all).each do |feed|
      Article.update_all('class_name = "RssArticle"', "feed_id = #{feed.id}")
    end
    ManualFeed.find(:all).each do |feed|
      Article.update_all('class_name = "ManualArticle"', "feed_id = #{feed.id}")
    end
    CacmFeed.find(:all).each do |feed|
      Article.update_all('class_name = "DLArticle"', "feed_id = #{feed.id}")
    end
  end

  def self.down
  end
end
