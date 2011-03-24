require File.dirname(__FILE__) + '/../spec_helper'

describe "Articles Helper" do
  include ArticlesHelper
  scenario :sections, :subjects

  before do
    self.stub!(:url_for).and_return("nothing interesting")
  end
  
  describe "rss feed info" do
    it "should deal with subjects correctly" do
      vertical = subjects(:artificial_intelligence)
      self.should_receive(:url_for).with(:controller => "subjects", :action => "syndicate", :subject => vertical.id, :only_path => false)
      ret = rss_feed_info(vertical)
      # the only semi-dynamic titles/sections are for subjects, so make sure it's doing the right thing.
      # not worried about sections and magazine since their titles and sections are totally hardcoded.
      ret[:title].should eql("Communications of the ACM: Artificial Intelligence")
      ret[:description].should eql("The latest news, opinion and research in artificial intelligence, from Communications online.")
    end
    it "should send the right params to url_for when passed a Section" do
      vertical = sections(:news)
      self.should_receive(:url_for).with(:controller => "sections", :action => "syndicate", :section => vertical.id, :only_path => false)
      ret = rss_feed_info(vertical)
    end
    it "should send the right params to url_for when passed an Issue" do
      vertical = create_model Issue
      self.should_receive(:url_for).with(:controller => "magazines", :action => "syndicate", :only_path => false)
      ret = rss_feed_info(vertical)      
    end
  end
end