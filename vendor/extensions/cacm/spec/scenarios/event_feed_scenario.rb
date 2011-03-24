class EventFeedScenario < Scenario::Base
  def load
    create_record FeedType, :events, :name => 'Events'
    create_record Feed, :conferences, :feed_type_id => feed_type_id(:events), :name => "Conferences", :feedurl => 'http://rss.acm.org/conferences/conferences.xml', :class_name => 'RssFeed'
  end
end