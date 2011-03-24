require File.dirname(__FILE__) + '/../spec_helper'

describe SessionController do

  describe "#create" do
    before do
      @session = Oracle::Session.new
      Oracle::Session.stub!(:new).and_return(@session)
      @login_params = { 'user' => 'u', 'passwd' => 'p'}
    end
    
    it "should redirect if successful" do
      @session.should_receive(:authenticate_user).with(@login_params).and_return(true)
      post :create, :current_member => @login_params
      response.should be_redirect
    end
    
    it "should render new if failed" do
      @session.should_receive(:authenticate_user).with(@login_params).and_return(false)
      post :create, :current_member => @login_params
      response.should render_template('new')
    end
    
    it "should unset return" do
      controller.session[:return] = 'foo'
      @session.should_receive(:authenticate_user).with(@login_params).and_return(true)
      post :create, :current_member => @login_params
      response.should be_redirect
      controller.session[:return].should be_nil
    end
    
    it "should redirect to original page if available" do
      request.env["HTTP_REFERER"] = '/article'
      @session.should_receive(:authenticate_user).with(@login_params).and_return(false)
      post :create, :current_member => @login_params
      response.should redirect_to('/article')
    end
  end
  
  describe "#destroy" do
    before do
      controller.current_member = Oracle::Session.new
      delete :destroy
    end
    
    it "should set current_member to nil" do
      controller.current_member.inst?.should be_nil
      controller.current_member.indv?.should be_nil
    end
    
    it "should redirect to root" do
      response.should be_redirect
    end
  end
  
  describe "#destroy" do
    it "should capture local referer" do
      referer = 'http://cacm.local:3000/referer'
      request.env["HTTP_REFERER"] = referer
      get :new
      controller.session[:return].should eql(referer)
    end
    
    it "should ignore remote referer" do
      request.env["HTTP_REFERER"] = 'http://remote.host/referer'
      get :new
      controller.session[:return].should be_nil
    end
  end

end
