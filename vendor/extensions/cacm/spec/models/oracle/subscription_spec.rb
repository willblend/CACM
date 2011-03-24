require File.dirname(__FILE__) + '/../../spec_helper'

describe Oracle::Subscription do

  before do
    @cursor = StubCursor.new
    @sub = Oracle::Subscription.new
    Oracle.connection.raw_connection.stub!(:parse).and_return(@cursor)
  end

  describe "#add_client" do
    it "should add a client" do
      @cursor[':r_str'] = 'Ok'
      @sub.subscribe_client('12345','josh@digitalpulp.com').should be_true
    end
  end

  describe "#remove_client" do
    it "should remove a client regardless of email" do
      @cursor[':r_str'] = 'Ok'
      @sub.unsubscribe_client('12345').should be_true
    end
  end

  describe "#client_subscribed?" do
    it "should return true if client is subscribed" do
      @cursor[':cur_status'] = 'subscribed'
      @sub.client_subscribed?('12345').should be_true
    end

    it "should return false if client is unsubscribed" do
      @cursor[':cur_status'] = 'unsubscribed'
      @sub.client_subscribed?('12345').should be_false
    end

    it "should return false if no client record" do
      @cursor[':cur_status'] = 'no record'
      @sub.client_subscribed?('12345').should be_false
    end
  end

  describe "#subscription_email" do
    it "should return email if found" do
      @cursor[':email'] = 'josh@digitalpulp.com'
      @sub.subscription_email(12345).should eql('josh@digitalpulp.com')
    end

    it "should return false if no email found" do
      @cursor[':email'] = nil
      @sub.subscription_email(12345).should be_false
    end
  end
end