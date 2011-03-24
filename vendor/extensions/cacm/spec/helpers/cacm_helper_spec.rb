require File.dirname(__FILE__) + '/../spec_helper'
include CacmHelper

describe "CACM Helper" do
  
  describe "month from number" do
    it "should return blank when given invalid arg" do
      month_from_number(99).should be_blank
    end
    
    it "should know that March is the third month" do
      month_from_number(3).should eql("March")
    end
    
    it "should know that November is the eleventh month" do
      month_from_number(11).should eql("November")
    end
  end
  
  describe "month options for select" do
    it "shouldn't have any selected month if we don't pass it one" do
      month_options_for_select(nil).should_not include("selected")
    end
    
    it "should return april selected if current month is april" do
      month_options_for_select(4).should include('<option value="4" selected="selected">April</option>')
    end    
  end
    
end