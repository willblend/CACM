class Feed < ActiveRecord::Base
  has_many :articles
  belongs_to :feed_type
  belongs_to_asset :default_article_image

  order_by "name ASC"

  # to precheck the appropriate items in the articles
  has_and_belongs_to_many :sections
  has_and_belongs_to_many :subjects

  validates_uniqueness_of :name
  validates_presence_of :name
  
  set_inheritance_column :class_name

  def self.picking_feeds
    Feed.find(:all, :conditions => {:feed_type_id => [FeedType.find_by_name("Article").id,FeedType.find_by_name("Blog").id]})
  end

  def self.book_feeds
    Feed.find_all_by_feed_type_id(FeedType.find_by_name("Books").id)
  end
  
  def self.course_feeds
    Feed.find_all_by_feed_type_id(FeedType.find_by_name("Courses").id)
  end

  def self.event_feeds
    Feed.find_all_by_feed_type_id(FeedType.find_by_name("Events").id)
  end

  def self.conference_feeds
    Feed.event_feeds
  end

  def display_name
    "Generic Feed"
  end

end
