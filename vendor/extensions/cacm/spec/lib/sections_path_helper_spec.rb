require File.dirname(__FILE__) + '/../spec_helper'

describe "Sections Path Helper" do
  include CACM::SectionsPathHelper
  scenario :sections, :subjects
  
  before do
    @article = Article.new(valid_article)
    @article.sections.clear
    @article.subjects.clear
    @article.sections << sections(:news)
    @article.sections << sections(:opinion)
    @article.sections << sections(:interviews)
    @article.sections << sections(:blog_cacm)
    @article.subjects << subjects(:communications_networking)
    @article.subjects << subjects(:computer_applications)
    @article.save
    @dl_article = CacmArticle.new(valid_article)
    @dl_article.save
    @session = Oracle::Session.new
    @session.stub!(:can_access?).and_return(true)
    self.stub!(:current_member).and_return(@session)
  end
  
  it "should correctly link to articles from /browse-by-subject if the article's subject is in the path" do
    ret = contextual_article_path(@article, "/browse-by-subject/communications-networking")
    ret.should eql("/browse-by-subject/communications-networking/#{@article.to_param}")
  end

  it "should link to the default article from /browse-by-subject if the article's subject isn't in the path" do
    ret = contextual_article_path(@article, "/browse-by-subject/artificial-intelligence")
    ret.should eql("/browse-by-subject/#{@article.subjects.first.to_param}/#{@article.to_param}")
  end

  it "should correctly link to CACM articles in the magazine" do
    source = stub(:source)
    issue = stub(:issue)
    issue.stub!(:source).and_return(source)
    source.stub!(:pub_date).and_return(Time.now)
    @dl_article.stub!(:source).and_return(source)
    @dl_article.stub!(:issue).and_return(issue)
    
    self.should_receive(:url_for).with(hash_including(:controller => '/magazines', :article => @dl_article))
    contextual_article_path(@dl_article, "/magazines")
  end

  it "should correctly link to articles from /opinion" do
    ret = contextual_article_path(@article, "/opinion/")
    ret.should eql("/opinion/articles/#{@article.to_param}")
  end
  
  it "should correctly link to articles from subsections of /opinion" do
    ret = contextual_article_path(@article, "/opinion/articles")
    ret.should eql("/opinion/articles/#{@article.to_param}")
    ret = contextual_article_path(@article, "/opinion/interviews")
    ret.should eql("/opinion/interviews/#{@article.to_param}")
  end
  
  it "should correctly link to articles from /blogs" do
    ret = contextual_article_path(@article, "/blogs")
    ret.should eql("/blogs/blog-cacm/#{@article.to_param}")
  end
  
  it "should correctly link to articles from other top-level pages" do
    ret = contextual_article_path(@article, "/news")
    ret.should eql("/news/#{@article.to_param}")    
  end
  
  it "should correctly link to article if the article has sections and no slug is passed in" do
    ret = contextual_article_path(@article)
    ret.should eql("/#{@article.sections.find(:first).to_param}/#{@article.to_param}")
  end
  
  it "should correctly link to article with no slug or sections if article has subjects" do
    @article.sections.clear
    ret = contextual_article_path(@article)
    ret.should eql("/browse-by-subject/#{@article.subjects.first.to_param}/#{@article.to_param}")
  end
  
  it "should call magazine_article_path on a CACM article with no slug provided" do
    source = stub(:source)
    issue = stub(:issue)
    issue.stub!(:source).and_return(source)
    source.stub!(:pub_date).and_return(Time.now)
    @dl_article.stub!(:source).and_return(source)
    @dl_article.stub!(:issue).and_return(issue)
    
    self.should_receive(:url_for).with(hash_including(:controller => '/magazines', :article => @dl_article))
    contextual_article_path(@dl_article, "")
  end
  
  it "should return the article's link rather than a site path if the article is a syndicated blog article" do
    @article = Article.new(valid_article)
    @article.sections.clear
    @article.subjects.clear
    @article.sections << sections(:syndicated_blogs)
    @article.link = "http://the.test.link"
    @article.save
    ret = contextual_article_path(@article)
    ret.should eql("http://the.test.link")
  end
  
  it "should not return the syndicated blog path if there are other sections assigned to the article" do
    # note that this is reliant on the sections scenario's positioning of sections correlating to the
    # sections' positioning in the actual system.  this test is mainly to show that if that ordering
    # is correct in the system, these conditions will be met.
    @article = Article.new(valid_article)
    @article.sections.clear
    @article.subjects.clear
    @article.sections << sections(:syndicated_blogs)
    @article.sections << sections(:opinion)
    @article.sections << sections(:interviews)
    @article.link = "http://the.test.link"
    @article.save
    ret = contextual_article_path(@article)
    ret.should eql("/#{@article.sections.find(:first).to_param}/#{@article.to_param}")
  end
  
  it "should return the homepage (/) if none of the above conditions are met" do
    @article.sections.clear
    @article.subjects.clear
    contextual_article_path(@article).should eql("/")
  end
  
  it "should link to abstract if not authorized" do
    @session.stub!(:can_access?).and_return(false)
    ret = contextual_article_path(@article, "/browse-by-subject/#{@article.subjects.first.to_param}")
    ret.should eql("/browse-by-subject/#{@article.subjects.first.to_param}/#{@article.to_param}")
  end
end