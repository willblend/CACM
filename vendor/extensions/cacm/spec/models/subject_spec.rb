require File.dirname(__FILE__) + '/../spec_helper'

describe Subject do
  before(:each) do
    @subject = Subject.new
  end

  it "should return a delimited list of keywords" do
    @subject.keywords << "foo"
    @subject.keywords << "bar"
    @subject.keywords.to_s.should eql("\"foo\" \"bar\"")
  end

  it "should be valid" do
    @subject.should be_valid
  end
end
