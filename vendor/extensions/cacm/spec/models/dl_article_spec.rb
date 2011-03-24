require File.dirname(__FILE__) + '/../spec_helper'

describe DLArticle do
  scenario :cacm_articles

  describe ".refresh" do
    before do
      @article = DLArticle.new(:oracle_id => 12345)
      DLArticle.stub!(:find_by_oracle_id).and_return(@article)
    end
    
    it "should query original" do
      Oracle::Article.should_receive(:find_by_id).with(12345).and_return(article_stub)
      @article.refresh
    end
  end

  describe "#track" do
    before do
      @article = DLArticle.new
      @stub = stub_everything(:stub)
      @article.stub!(:source).and_return(@stub)
      @article.stub!(:hits).and_return(@stub)
      
      @request = ActionController::TestRequest.new
      @request.session[:oracle] = Oracle::Session.new
      
      @curb = stub_everything(:curb)
      Curl::Easy.stub!(:new).and_return(@curb)
    end

    it "should register hit locally" do
      @stub.should_receive(:create).with(:request => @request)
      @article.track(:request => @request, :format => :html)
    end
    
    it "should register hit remotely" do
      @curb.should_receive(:http_head)
      @article.track(:request => @request, :format => :html)
    end
  end
  
  describe "page and vol methods" do
    before do
      @source = stub_everything(:source)
      @article = DLArticle.new
      @article.stub!(:source).and_return(@source)
    end

    it "should format single source page" do
      @source.stub!(:start_page).and_return('1')
      @source.stub!(:end_page).and_return(nil)
      @article.pages.should eql('Page 1')
    end

    it "should format multiple source pages" do
      @source.stub!(:start_page).and_return('1')
      @source.stub!(:end_page).and_return('2')
      @article.pages.should eql('Pages 1-2')
    end
    
    it "should format vol, issue, and pages" do
      @article.stub!(:issue).and_return(@source)
      @source.stub!(:volume).and_return('54')
      @source.stub!(:number).and_return('3')
      @article.stub!(:pages).and_return('Page 1')
      @article.vol_issue_page.should eql('Vol. 54 No. 3, Page 1')
    end
  end

end