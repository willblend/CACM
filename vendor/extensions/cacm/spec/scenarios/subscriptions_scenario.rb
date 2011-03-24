class SubscriptionsScenario < Scenario::Base
  def load
    create_record :subscription, :basic, :email => 'basic@digitalpulp.com', :client_id => 12345
  end
end