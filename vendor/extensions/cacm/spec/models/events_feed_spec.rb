require File.dirname(__FILE__) + '/../spec_helper'
require 'rfeedparser'
require 'digest/md5'
      
describe RssFeed do
  scenario :event_feed
  
    before do
      @items = File.open("#{CacmExtension.root}/spec/fixtures/events_feed.yml") { |file| YAML::load(file) }
      @items.entries.first.stub!(:updated_time).and_return(Time.now - 1.year)
      @items.entries.last.stub!(:updated_time).and_return(Time.now + 1.year)
      FeedParser.stub!(:parse).and_return(@items)
      @feed = feeds(:conferences)
      @feed.ingest
    end
  
    it "should not import events before today" do
      Article.count.should eql(1)
    end
end