class FeedsScenario < Scenario::Base
  uses :feed_types
  def load
    create_model CacmFeed, :cacm, :name => 'Communications of the ACM', :feed_type_id => feed_types(:cacm_feed_type).id, :class_name => 'CacmFeed'
  end
end