require File.dirname(__FILE__) + '/../spec_helper'

describe TimedFileStore do
  before do
    @store = TimedFileStore.new('.')
  end
  
  describe "#cache_valid?" do
    it "should reject expired caches" do
      File.stub!(:mtime).and_return((TimedFragmentsExtension::FRAGMENT_LIFETIME + 1.minute).ago)
      @store.cache_valid?('blah').should be_false
    end
    
    it "should pass valid caches" do
      File.stub!(:mtime).and_return((TimedFragmentsExtension::FRAGMENT_LIFETIME - 1.minute).ago)
      @store.cache_valid?('blah').should be_true
    end
    
    it "should rescue errors" do
      File.stub!(:mtime).and_raise(SystemCallError)
      @store.cache_valid?('blah').should be_false
    end
    
    it "should accept an expiry param" do
      File.stub!(:mtime).and_return((TimedFragmentsExtension::FRAGMENT_LIFETIME - 1.minute).ago)
      @store.cache_valid?('blah', 30.seconds).should be_false
    end
  end
end