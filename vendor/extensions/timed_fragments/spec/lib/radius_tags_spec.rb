require File.dirname(__FILE__) + '/../spec_helper'

describe TimedFileStore::RadiusTags do
  scenario :pages

  describe "cache" do
    it "should return cache" do
      Page.new.cache 'test' do
        'cached content'
      end.should eql('cached content')
    end
    
    it "should take an expiry param" do
      page = Page.new
      page.stub!(:perform_caching).and_return(true)
      page.should_receive(:read_fragment).with('test', 60.minutes)
      page.cache 'test', 60.minutes do
        'cached content'
      end
    end
  end
  
  describe "r:cache" do
    before do
      @page = pages(:home)
    end

    it "should use name if given" do
      @page.should_receive(:cache).with('test', nil)
      @page.should render("<r:cache name='test'>content</r:cache>")
    end

    it "should merge attrs with params" do
      @page.should_receive(:cache).with(hash_including(:foo => 'bar'), nil)
      @page.should render("<r:cache foo='bar'>content</r:cache>")
    end
    
    it "should pass time as a separate param" do
      @page.should_receive(:cache).with(hash_including(:foo => 'bar'), 300)
      @page.should render("<r:cache foo='bar' time='300'>content</r:cache>")
    end
  end

end