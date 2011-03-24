require File.dirname(__FILE__) + '/../spec_helper'

describe Page do
  before do
    @page = Page.new
    @page.stub!(:valid?).and_return(true)
    root = mock('root')
    site = mock('site')
    site.stub!(:id).and_return(1234)
    root.stub!(:site).and_return(site)
    @page.stub!(:root).and_return(root)
  end
  
  it "should set site ID on save" do
    @page.save
    @page.site_id.should eql(1234)
  end
end