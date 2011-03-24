require File.dirname(__FILE__) + '/../spec_helper'

describe SphinxSearchExtension do
  
  it "should add Search toggle to admin UI" do
    admin = Radiant::AdminUI.instance
    admin.page.edit.extended_metadata.should include("search_toggle")
  end
  
  it "should include PageExtensions" do
    Page.should include(SphinxSearch::PageExtensions)
  end
  
  it "should include SiteExtensions" do
    Site.should include(SphinxSearch::SiteExtensions)
  end

end