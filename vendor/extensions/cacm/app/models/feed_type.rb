class FeedType < ActiveRecord::Base
  has_many :feeds
  validates_uniqueness_of :name
end
