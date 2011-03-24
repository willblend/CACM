require File.dirname(__FILE__) + '/../../spec_helper'

describe CacmAdmin::IngestController do
  scenario :users

  describe "#create" do
    before do
      @feed = DLFeed.new
      Feed.stub!(:find).and_return(@feed)

      login_as(:admin)
    end

    it "should create a new article" do
      @article = DLArticle.new
      DLArticle.stub!(:find_by_oracle_id).and_return(nil)
      DLArticle.stub!(:find_by_uuid).and_return(nil)
      @feed.stub!(:ingest).and_return(@article)

      get :create, :id => 9999
      response.should redirect_to(edit_admin_article_path(@article))
    end

    it "should report duplicates" do
      @article = DLArticle.new
      DLArticle.stub!(:find_by_oracle_id).and_return(@article)

      get :create, :id => 9999
      response.should render_template('new')
    end

    it "should report bogus IDs" do
      DLArticle.stub!(:find_by_oracle_id).and_return(nil)
      DLArticle.stub!(:find_by_uuid).and_return(nil)
      @feed.stub!(:ingest).and_return(nil)

      get :create, :id => 9999
      response.should render_template('new')
    end
  end

end
