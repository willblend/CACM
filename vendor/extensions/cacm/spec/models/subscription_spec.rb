require File.dirname(__FILE__) + '/../spec_helper'

describe Subscription do
  scenario :subscriptions

  before(:each) do
    @oracle = StubCursor.new
    @oracle.stub!(:client_subscribed?).and_return(true)
    @oracle.stub!(:subscription_email).and_return(nil)
    Oracle::Subscription.send(:class_variable_set, :@@conn, @oracle)
    Oracle::Subscription.stub!(:new).and_return(@oracle)
  end

  describe "initialize" do
    it "should use Oracle email" do
      @oracle.stub!(:subscription_email).and_return('josh@digitalpulp.com')
      subscriptions(:basic).email.should eql('josh@digitalpulp.com')
    end

    it "should skip email update if Oracle value is blank" do
      subscriptions(:basic).email.should eql('basic@digitalpulp.com')
    end
  end

  describe "#after_save" do
    before do
      @sub = subscriptions(:basic)
      @sub.stub!(:source).and_return(@oracle)
    end

    it "should subscribe user if @toc = true" do
      @oracle.should_receive('subscribe_client').with(@sub.client_id, 'josh@digitalpulp.com')
      @oracle.should_not_receive('unsubscribe_client').with(@sub.client_id, @sub.email)
      @sub.email = 'josh@digitalpulp.com'
      @sub.toc = true
      @sub.save
    end

    it "should unsubscribe user if @toc = false" do
      @oracle.should_receive('subscribe_client').with(@sub.client_id, 'josh@digitalpulp.com')
      @oracle.should_receive('unsubscribe_client').with(@sub.client_id)
      @sub.email = 'josh@digitalpulp.com'
      @sub.toc = false
      @sub.save
    end
  end
end
