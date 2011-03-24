class FeedTypesScenario < Scenario::Base
  def load
    create_model FeedType, :cacm_feed_type, :name => 'CacmFeedType'
    create_model FeedType, :article, :name => 'Article'
  end
end