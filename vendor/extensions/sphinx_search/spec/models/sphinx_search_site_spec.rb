require File.dirname(__FILE__) + '/../spec_helper'

describe Site do

  it "should set site_id on newly created homepage" do
    site = Site.create(:name => 'test', :base_domain => 'test.host')
    site.homepage.site_id.should eql(site.id)
  end

end