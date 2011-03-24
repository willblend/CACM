require File.dirname(__FILE__) + '/../../spec_helper'

describe CacmAdmin::ArticlesController do
  scenario :users, :feeds, :sections
  
  before do
    login_as :admin
  end

  describe "#new" do
    it "should populate the feed" do
      get :new, :provider_id => feeds(:cacm).id
      assigns(:article).feed_id.should eql(feeds(:cacm).id)
    end
    
    it "should redirect to index if no provider_id is given" do
      controller.stub!(:index_options).and_return({})
      get :new
      response.should redirect_to(admin_articles_path)
    end

    it "should render new if provider_id is given" do
      controller.stub!(:index_options).and_return({})
      get :new, :provider_id => feeds(:cacm).id
      response.should render_template("new")
    end

    it "should redirect to index if an invalid provider_id is provided" do
      controller.stub!(:index_options).and_return({})
      get :new, :provider_id => -1
      response.should redirect_to(admin_articles_path)     
    end

    it "should prepopulate the article's sections with any default sections for the feed" do
      feeds(:cacm).sections << sections(:news)
      get :new, :provider_id => feeds(:cacm).id
      assigns(:article).sections.should eql([sections(:news)])
    end

  end

  describe "#edit" do
    before do
      @session = Oracle::Session.new
      controller.stub!(:current_member).and_return(@session)
      Article.stub!(:find).and_return(Article.new)
    end

    it "should authenticate an admin" do
      @session.should_receive(:authenticate_user)
      get :edit, :id => 999
    end

    it "should not re-authenticate an admin" do
      @session.should_receive(:indv?).and_return(true)
      @session.should_not_receive(:authenticate_user)
      get :edit, :id => 999
    end
  end

end
