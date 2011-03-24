require File.dirname(__FILE__) + '/../spec_helper'

describe Article do
  scenario :sections, :subjects

  describe "approved_at behavior" do
    it "approved_at should be nil upon article creation" do
      article = Article.new(valid_article)
      article.save!
      article.approved_at.should be(nil)
    end
    
    it "approved_at should be set upon article approval" do
      article = Article.new(valid_article)
      article.approve!
      article.approved_at.should_not be(nil)
    end
    
    it "approved_at should be nil upon article rejection" do
      article = Article.new(valid_article)
      article.reject!
      article.approved_at.should be(nil)
    end
    
    it "should not change the approved_at value if the article is only saved" do
      article = Article.new(valid_article)
      article.approve!
      a = article.approved_at
      article.title = "now THIS is a new title."
      article.save
      article.approved_at.should eql(a)
    end
    
    
  end
  
  describe "top_five section based articles" do
    it "should scope the articles returned to the method called which determines the section" do
      articles = Article.most_discussed_careers_articles
      articles.each do |article|
        article.sections.select { |s| s.name == "Careers" }.should_not be_empty
      end
    end
    
    it "should not return any articles for a bogus section" do
       articles = Article.most_discussed_careers_articles
       articles.each do |article|
         article.sections.select { |s| s.name == "Carpentry" }.should be_empty
      end
    end
    
    it "should return the article with the most comments first" do
      articles = Article.most_discussed_careers_articles
      articles.first.comments.length.should be >= articles[1].comments.length
    end
    
    it "should return the articles in descending order based on number of comments" do
      articles = Article.most_discussed_careers_articles
      articles.first.comments.length.should be >= articles.last.comments.length
    end
  end
  
  describe "top_five subject based articles" do
    it "should return only articles for the subject passed in" do
      articles = Article.most_discussed_articles_for_subject("Cats")
      articles.each do |article|
        article.subjects.select { |s| s.name == "Cats" }.should_not be_empty
        article.subjects.select { |s| s.name == "Entertainment" }.should be_empty
      end
    end
    
    it "should return the article with the most comments first" do
      articles = Article.most_discussed_articles_for_subject("Cats")
      articles.first.comments.length.should be >= articles[1].comments.length
    end
    
    it "should return the articles in descending order based on number of comments" do
      articles = Article.most_discussed_articles_for_subject("Cats")
      articles.first.comments.length.should be >= articles.last.comments.length
    end
    
    it "should clean short descriptions of linked images when saving" do
      article = Article.new(valid_article)
      # Give it an evil short description with linked images, some just an image, some with additional linked text
      article.short_description = %{
        <p id="some-description">
          <a href="google.com"><img src="/images/blah.gif" alt="blah" /></a> That link goes to google!
          <br />
          <a href="yahoo.com"><img src="/images/blah2.gif" alt="blah2" /> And this is some linked text to yahoo!
          <br />
          And a linked line break!
          </a>
          No more linked text.
        </p>
      }
      article.save!
      article.short_description.should_not have_tag("img")
    end
    
  end
  
  describe "before_save sanatize attributes" do
    it "should save" do
        a = Article.new
        a.date = Time.now
        a.uuid = "fdskgngklsnkgglsdg"
        a.feed_id = 1111
        a.stub!(:is_displayed_on_site?).and_return(true)
        %w(author title full_text short_description description keyword).each do |attributes|
          a.send("#{attributes}=","Hello &amp; Goodbye")
        end
        a.save
        a.should be_valid
    end
    it "sanatize attributes and decode entities to utf8 characters" do
       a = Article.new
       a.date = Time.now
       a.title = "bleh"
       a.uuid = "fdskgngklsnkgglsdg"
       a.feed_id = 1111
       a.stub!(:is_displayed_on_site?).and_return(true)
       a.full_text = "Hello &amp; Goodbye"
       a.author = "Hello &amp; Goodbye"
       a.keyword = "Hello &amp; Goodbye"
       a.short_description = "Hello &amp; Goodbye"
       a.save!
       
       a.author.should eql("Hello & Goodbye")   
       a.keyword.should eql("Hello & Goodbye")
    end
  end
  
  describe "#keywords" do
    it "should inherit subject keywords" do
      subjects(:artificial_intelligence).keywords << 'ai'
      subjects(:computer_applications).keywords << 'apps'
      
      a = Article.new
      a.subjects = [subjects(:artificial_intelligence), subjects(:computer_applications)]
      a.keywords.should eql([Keyword.find_by_name('ai'), Keyword.find_by_name('apps')])
    end
  end

end
