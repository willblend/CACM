require File.dirname(__FILE__) + '/../spec_helper'
include CACM::WillPaginateForRadiant::Paginator

describe "will_paginate_for_radiant" do
  scenario :subjects, :cacm_articles
    
  describe "parameter handling and link renderer class" do
    before(:each) do
      @renderer = CACM::WillPaginateForRadiant::LinkerRenderer.new
      @collection = Article.paginate(:all, :per_page => 5, :page => 1)
      @relative_url = '/'
    end  
      
    it "should return the correct month and year for the query string of the links generated " do
      @parameters = {'year' => 2008, 'month' => 9}
      @parameters = CACM::WillPaginateForRadiant::Paginator.query_stringify(@parameters)
      expected = "href='/?p=2&month=9&year=2008"
      
      @renderer.prepare(@collection, @relative_url,@parameters)  
      @renderer.to_html.should include(expected)
    end
    
    it "should pass back any get params that exist in the initial requesting page" do
      @parameters = {'year' => 2008, 'month' => 9, 'foo' => 'bar'}
      @parameters = CACM::WillPaginateForRadiant::Paginator.query_stringify(@parameters)
      expected = "href='/?p=2&month=9&foo=bar&year=2008"
      
      @renderer.prepare(@collection, @relative_url,@parameters)  
      @renderer.to_html.should include(expected)
    end
    
    it "should pass back any get params that exist in the initial requesting page" do
      @parameters = {'year' => 2008, 'month' => 9, 'foo' => 'bar', 'another' => 'get_var'}
      @parameters = CACM::WillPaginateForRadiant::Paginator.query_stringify(@parameters)
      expected = "href='/?p=2&month=9&another=get_var&foo=bar&year=2008"
      
      @renderer.prepare(@collection, @relative_url,@parameters)  
      @renderer.to_html.should include(expected)
    end 
  end
  
  describe "main paginater module functionality" do
    before(:each) do
      @collection = Article.paginate(:all, :per_page => 5, :page => 1)
      @parameters = {'year' => 2008, 'month' => 9}
    end
    
    it "should render some pagination when a collection is specified" do
      rendered = will_paginate_radiant(@collection, @parameters)
      expected = "href='/?p=2&month=9&year=2008"
      rendered.should include(expected)
    end
    
    it "should preseve the get params passed and append them to the result set links" do
      parameters = {'year' => 2008, 'month' => 9, 'foo' => 'bar'}
      rendered = will_paginate_radiant(@collection, parameters)
      expected = "href='/?p=2&month=9&foo=bar&year=2008"
      rendered.should include(expected) 
    end
    
    it "should keep the current month and year select and append them as params to the links" do
      parameters = {'year' => 2021, 'month' => 9}
      rendered = will_paginate_radiant(@collection, parameters)
      expected = "href='/?p=2&month=9&year=2021"
      rendered.should include(expected)
    end
    
    it "should render nil if there is no paging need" do
      collection = Article.paginate(:all, :per_page => 5000, :page => 1)
      rendered = will_paginate_radiant(collection, @parameters)
      rendered.should eql(nil)
    end
    
    it "should raise an error the main method is called with no collection" do
      collection = nil
      lambda { will_paginate_radiant(collection, @parameters) }.should raise_error(ArgumentError)
    end
    
  end
end