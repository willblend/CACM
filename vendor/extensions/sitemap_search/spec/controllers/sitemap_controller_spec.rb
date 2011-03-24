require File.expand_path(File.dirname(__FILE__) + '../../spec_helper')
 
class StubController < ApplicationController 
  no_login_required
  include SitemapSearch::Controller
end



describe StubController do
    scenario :pages
    
    before do
      @page = pages(:home)
    end
    
    it "find the search method that has been included in this stub controller" do
       StubController.new.respond_to?(:search).should be_true
    end
    
    it "should assign the site_id to a hidden element" do
      site = Site.find(:first)
      get :search, :query => "a query"
      assigns(:current_site).should eql(site)
    end
    
    it "should assign the query varible" do
      get :search , :query => "another search query"
      assigns(:query).should eql("another search query")
    end
    
    it "should redirect a user to the page_index action if no query is supplied" do
      get :search, :query => " ", :search_type => "full-text"
      response.should redirect_to(page_index_path)
    end
    
    it "should redirect a user to a page_index action if a view all (this is a value of 0) is selected for a filter" do
      get :search, :filter => "0", :search_type  => "filter"
      response.should redirect_to(page_index_path)
    end
    
end