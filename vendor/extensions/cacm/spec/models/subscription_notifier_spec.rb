require File.dirname(__FILE__) + '/../spec_helper'

describe SubscriptionNotifier do
  scenario :subscriptions, :sections, :subjects
  
  before do
    ActionMailer::Base.delivery_method = :test  
    ActionMailer::Base.perform_deliveries = true  
    ActionMailer::Base.deliveries = []
  end
  
  describe "email alert" do
    before do
      subscriptions(:basic).subscribables << subjects(:artificial_intelligence)
      subscriptions(:basic).subscribables << sections(:opinion)
      @html = {subjects(:artificial_intelligence) => "<h1>hello AI</h1>", sections(:opinion) => "No new articles this week."}
      @plaintext = {subjects(:artificial_intelligence) => "hello AI", sections(:opinion) => "No new articles this week."}
      @email_promo = "<img />"
      @response = SubscriptionNotifier.create_email_alert(subscriptions(:basic), @html, @plaintext, @email_promo)
    end
    it "should create an email alert to the subscriber's address" do
      @response.to.should include(subscriptions(:basic).email)
    end
    it "should include an html version" do
      @response.body.should include(@html[subjects(:artificial_intelligence)])
      @response.body.should include(@html[sections(:opinion)])
    end
    it "should include a plaintext version" do
      @response.body.should include(@plaintext[subjects(:artificial_intelligence)])
      @response.body.should include(@plaintext[sections(:opinion)])
    end
  end
end