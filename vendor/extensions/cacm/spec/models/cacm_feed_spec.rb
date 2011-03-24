require File.dirname(__FILE__) + '/../spec_helper'

class CacmArticle
  def stub_link
    true
  end
end

describe CacmFeed do
  scenario :feeds, :cacm_articles, :issues
  
  describe "#ingest" do
    before(:all) do
      CacmArticle.send :alias_method, :link_to_issue_orig, :link_to_issue
      CacmArticle.send :alias_method, :link_to_issue, :stub_link
    end

    before(:each) do
      @cacm = feeds(:cacm)
      CACM.const_set("CACM_FEED_ID", @cacm.id) unless CACM::CACM_FEED_ID.eql?(@cacm.id)
      @issue = issues(:december)
    end

    after(:all) do
      CacmArticle.send :alias_method, :link_to_issue, :link_to_issue_orig
    end

    it "should pull recent cacm articles" do
      Issue.stub!(:find).and_return(@issue)
      CacmArticle.stub!(:find_by_oracle_id).and_return(wrapped_oracle_stub)
      Oracle::Article.should_receive(:find) do |count,conditions|
        count.should eql(:all)
        conditions[:conditions][1].should eql(oracle_stub.created_date)
        conditions[:conditions][2].should eql(CACM::PUB_ID)
        [ ] # dummy return val
      end
      @cacm.ingest
    end

    it "should cast articles to CacmArticles" do
      Issue.stub!(:find).and_return(@issue)
      Oracle::Article.stub!(:find).and_return(oracle_stub)
      Oracle::Article.stub!(:find_by_id).and_return(article_stub)
      lambda do
        @cacm.ingest
      end.should change(CacmArticle, :count).by(1)
    end

    it "should set feed id" do
      Issue.stub!(:find).and_return(@issue)
      Oracle::Article.stub!(:find).and_return(oracle_stub)
      Oracle::Article.stub!(:find_by_id).and_return(article_stub)
      @cacm.ingest
      Article.find(:first, :order => 'created_at DESC').feed.should eql(@cacm)
    end

    it "should display name" do
      @cacm.display_name.should eql("(CACM Articles)")
    end

  end
end