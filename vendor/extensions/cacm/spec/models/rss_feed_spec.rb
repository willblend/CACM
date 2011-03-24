require File.dirname(__FILE__) + '/../spec_helper'
require 'rfeedparser'

describe RssFeed do

  describe "Ingest" do
    before do
      require 'digest/md5'
      fix = "#{CacmExtension.root}/spec/fixtures/feed.yml"
      @feeds = File.open(fix) { |yf| YAML::load(yf) }
      FeedParser.stub!(:parse).and_return(@feeds)
      @blog_type = FeedType.new({:name => 'Blog'})
      @blog_type.save
      @job_type = FeedType.new({:name => 'Jobs'})
      @job_type.save
      @blogfeed = {:feed_type_id => @blog_type[:id], :name => "Feed1"}
      @jobfeed = {:feed_type_id => @job_type[:id], :name => "Feed2"}
      Article.destroy_all
    end
  
    it "should import unique articles" do
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all)
      a.size.should eql(@feeds.entries.size)
    end

    it "should not import articles with duplicate UUIDs" do
      @feeds.entries[1]["id"] = @feeds.entries[0]["id"]
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all)
      a.size.should eql(@feeds.entries.size - 1)      
    end

    it "should automatically generate a UUID for an article if none is provided in the feed" do
      @feeds.entries[0]["id"] = nil
      feed_link = @feeds.entries[0]["link"]
      f = RssFeed.new(@blogfeed)
      f.feedurl = "www.blah.edu"
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["link = ?", feed_link])
      a[0].link.should_not be_nil
    end

    it "should default to the Feed author if none is provided for the article" do
      @feeds.entries[0]["author"] = nil
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[0]["id"])
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].author.should eql(@feeds.feed.author)
    end
    
    it "should use the description for an entry if no additional content is available for the full text" do
      @feeds.entries[0].content = nil
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[0]["id"])
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].full_text.should eql(@feeds.entries[0].description)
    end
    
    it "should store the job location in the short description if the feed type is Jobs" do
      loc = "Topeka, KS"
      @feeds.entries[0]["jobs_location"] = loc
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[0]["id"])
      f = RssFeed.new(@jobfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].short_description.should eql(loc)
    end
    
    it "should store the company as the author if the feed type is Jobs" do
      company = "Dunder-Mifflin"
      @feeds.entries[0]["jobs_company"] = company
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[0]["id"])
      f = RssFeed.new(@jobfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].author.should eql(company)
    end
    
    it "should add <p> tags to an article's full_text if the article's first tag isn't a block element" do
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[2]["id"])
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].full_text.should include("<p>")
    end

    it "should not add <p> tags to an article's full_text if the article's first tag is a block element" do
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[3]["id"])
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].full_text.should_not include("<p>")
    end

    it "should strip out feedburner junk" do
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[4]["id"])
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].full_text.should_not include("feedflare")
      a[0].full_text.should_not include("<img>")
    end

    it "should not strip out non-feedburner junk" do
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[5]["id"])
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].full_text.should_not include("<p>")
      a[0].full_text.should_not include("<img>")
    end
    
    it "should automatically approve RSS feed items that are from Blog feeds" do
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[5]["id"])
      f = RssFeed.new(@blogfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].state.should eql("approved")
    end

    it "should not approve RSS feed items that aren't from Blog feeds" do
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[5]["id"])
      f = RssFeed.new(@jobfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].state.should eql("new")
    end
    
    it "should use the feedburner:origLink instead of the link for the article's link if one is present" do
      feed_uuid = Digest::MD5.hexdigest(@feeds.entries[1]["id"])
      @feeds.entries[1]["link"] = "link"
      @feeds.entries[1]["feedburner_origlink"] = "feedburnerlink"
      f = RssFeed.new(@jobfeed)
      f.save
      f.ingest
      a = Article.find(:all, :conditions => ["uuid = ?", feed_uuid])
      a[0].link.should eql("feedburnerlink")
    end

    it "should display name" do
      RssFeed.new(@jobfeed).display_name.should eql("RSS Feed: #{@job_type.name}")
    end
    
  end
end