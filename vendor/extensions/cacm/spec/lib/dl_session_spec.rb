require File.dirname(__FILE__) + '/../spec_helper'

class StubController < ApplicationController
  include CACM::DLSession
end

describe StubController, :type => :controller do
  before do
    @controller = StubController.new
    @controller.session = Hash.new
    @controller.stub!(:request).and_return(@request)
    @session = Oracle::Session.new
  end
  
  it "should have authenticate_by_ip before filter" do
    StubController.filter_chain.find { |x| x.filter == :authenticate_by_ip }.should_not be_nil
  end
  
  describe "#current_member" do
    it "should return oracle session if set" do
      @controller.session = { :oracle => @session }
      @controller.current_member.should eql(@session)
    end
    
    it "should return new session if unset" do
      Oracle::Session.stub!(:new).and_return(@session)
      @controller.current_member.should eql(@session)
    end
    
    it "should include IP when instantiating a new session" do
      request.remote_addr = '127.0.0.1'
      @controller.current_member.ip.should eql('127.0.0.1')
    end
  end
  
  describe "#current_member=" do
    it "should set current member if session given" do
      @session.instance_variable_set(:@inst_client, '12345')
      @controller.current_member = @session
      @controller.instance_variable_get(:@current_member).should eql(@session)
    end
    
    it "should set member to nil" do
      @controller.current_member = false
      @controller.current_member.indv?.should be_nil
      @controller.current_member.inst?.should be_nil
    end
  end
  
  describe "authenticate_by_ip" do
    before do
      Oracle::Session.stub!(:new).and_return(@session)
    end
    
    it "should return if member exists" do
      @session.instance_variable_set(:@inst_client, '12345')
      @controller.session[:oracle] = @session
      @session.should_not_receive(:authenticate_ip)
      @controller.send(:authenticate_by_ip)
    end
    
    it "should set current member if ip authenticates" do
      @session.should_receive(:authenticate_ip).and_return(true)
      @controller.send(:authenticate_by_ip)
      @controller.current_member.should eql(@session)
    end
    
    it "should skip check if user is a local crawler" do
      request.stub!(:remote_ip).and_return(CACM::CRAWLER_IPS.first)
      @session.should_not_receive(:authenticate_ip)
      @controller.send(:authenticate_by_ip).should be_true
    end
    
    it "should skip check if user is an external crawler" do
      request.stub!(:user_agent).and_return('Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)')
      @session.should_not_receive(:authenticate_ip)
      @controller.send(:authenticate_by_ip).should be_false
    end
  end
end