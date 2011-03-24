require File.dirname(__FILE__) + '/../spec_helper'

describe DLFeed do
  before do
    Oracle::Article.stub!(:find_by_id).and_return(stub_everything)
    @dl = DLFeed.new
  end
  
  it "should have a display name" do
    @dl.display_name.should eql '(DL Articles)'
  end
  
  it "should return a new article upon ingest" do
    @article = DLArticle.new
    DLArticle.stub!(:retrieve).and_yield(@article).and_return(@article)
    @dl.ingest(:bogus).should eql(@article)
  end
  
  it "should return nil if ingest failed" do
    DLArticle.stub!(:retrieve).and_return(nil)
    @dl.ingest(:bogus).should be_nil
  end
  
  it "should cast article to appropriate subclass prior to ingestion" do
    @article = mock(:article, :publication_id => CACM::UBIQUITY_ID)
    Oracle::Article.stub!(:find_by_id).and_return(@article)
    UbiquityArticle.should_receive(:retrieve).and_yield(stub_everything).and_return(stub_everything)
    @dl.ingest(:bogus)
  end
end