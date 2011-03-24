require File.dirname(__FILE__) + '/../../spec_helper'

describe Oracle::Client do
  before do
    @cursor = StubCursor.new
    @account = Oracle::WebAccount.new
    Oracle.connection.raw_connection.stub!(:parse).and_return(@cursor)
  end
  
  describe "#find_by_email" do
    before do
      @cursor[':o_client_no'] = '12345'
      @cursor[':o_client_type'] = 'ACM MEMBER'
      @cursor[':o_username'] = 'josh'
    end

    it "should not return a client if client as a web account" do
      @cursor[':o_status'] = 'ACCOUNT EXISTS'
      Oracle::Client.find_by_email('josh@digitalpulp.com').should be_false
    end
    
    it "should return a single client if one record is found" do
      @cursor[':o_status'] = 'FOUND'
      client = Oracle::Client.find_by_email('josh@digitalpulp.com')
      client.email.should eql('josh@digitalpulp.com')
      client.id.should eql('12345')
      client.username.should eql('josh')
    end
    
    it "should return a single client if multiple records are found" do
      @cursor[':o_status'] = "MULTIPLE FOUND"
      client = Oracle::Client.find_by_email('josh@digitalpulp.com')
      client.email.should eql('josh@digitalpulp.com')
      client.id.should eql('12345')
      client.username.should eql('josh')
    end
  end
end