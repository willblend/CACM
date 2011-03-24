require File.dirname(__FILE__) + '/../spec_helper'

describe CacmArticle do
  scenario :cacm_articles, :articles_base, :issues

  describe ".refresh" do
    it "should retrieve metadata" do
      @article = CacmArticle.new(:feed => feeds(:cacm))
      DLArticle.stub!(:find_by_oracle_id).and_return(@article)
      Oracle::Article.stub!(:find_by_id).and_return(article_stub)
      @article.stub!(:link_to_issue).and_return(true)

      @article.refresh
      {:title => 'Article Stub', :author => 'Author Name', 
       :short_description => 'Lorem ipsum dolor', :link => 'http://digitalpulp.com'}.each_pair do |key,value|
         @article.send(key).should eql(value)
       end
    end
  end

  describe ".retrieve" do
    it "should insert parsed data" do
      oracle = article_stub
      Oracle::Article.stub!(:find_by_id).and_return(oracle)

      article = CacmArticle.new(:feed => feeds(:cacm))
      CacmArticle.stub!(:new).and_return(article)

      article.stub!(:extract_cacm_content).and_return(
        { :full_text => 'full text',
          :leadin => 'lead in',
          :toc => 'table of contents' })
      article.stub!(:fetch_dl_data).and_return('')
      article.stub!(:link_to_issue).and_return(true)

      local = CacmArticle.retrieve(9999)
      local.full_text.should eql('full text')
    end

    it "should set feed defaults" do
      oracle = article_stub
      Oracle::Article.stub!(:find_by_id).and_return(oracle)

      f = feeds(:cacm)
      f.digital_library = false
      f.acm_resource = true
      f.user_comments = true
      f.news_opinion = false
      f.save

      article = CacmArticle.new(:feed => feeds(:cacm))
      CacmArticle.stub!(:new).and_return(article)

      article.stub!(:extract_cacm_content).and_return(
        { :full_text => 'full text',
          :leadin => 'lead in',
          :toc => 'table of contents' })
      article.stub!(:fetch_dl_data).and_return('')
      article.stub!(:link_to_issue).and_return(true)

      local = CacmArticle.retrieve(9999)
      local.digital_library.should eql(false)
      local.acm_resource.should eql(true)
      local.user_comments.should eql(true)
      local.news_opinion.should eql(false)
    end
  end
end