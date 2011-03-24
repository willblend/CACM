class IssuesScenario < Scenario::Base
  def load
    create_model Issue, :december, :state => 'new'
  end
end