require File.dirname(__FILE__) + '/../../spec_helper'

describe "Endeca::ResultSet" do
  before do
    @set = Endeca::ResultSet.new
  end

  describe "#sample" do
    it "should reject items older than 1 year" do
      4.times do
        @set << Endeca::Result.new(:publication_date => Time.now.to_s)
      end

      current = Endeca::Result.new(:publication_date => Time.now.to_s)
      old = Endeca::Result.new(:publication_date => 2.years.ago.to_s)
      @set << current
      @set << old
      
      @set.sample(5).should include(current)
      @set.sample(5).should_not include(old)
    end
    
    it "should reject items from the CACM" do
      4.times do
        @set << Endeca::Result.new(:publication_date => Time.now.to_s, :publication_title => "Journal of Stuff")
      end
      cacm = Endeca::Result.new(:publication_date => Time.now.to_s, :publication_title => "Communications of the ACM")
      other = Endeca::Result.new(:publication_date => Time.now.to_s, :publication_title => "Journal of Stuff")
      @set << cacm
      @set << other
      
      @set.sample(5).should include(other)
      @set.sample(5).should_not include(cacm)
    end

    it "should find an item from multiple classifications" do
      titles = %w(alpha beta)
      titles.each do |title|
        2.times { @set << Endeca::Result.new(:publication_date => Time.now.to_s, :publication_title => title) }
      end
      samples = @set.sample(2)
      titles.each do |title|
        samples.should have_publication(title)
      end      
    end

    it "should loop through classifications if hash size > n" do
      titles = %w(alpha beta gamma delta epsilon)
      titles.each_with_index do |title, i|
        (i+1).times { @set << Endeca::Result.new(:publication_date => Time.now.to_s, :publication_title => title) }
      end
      samples = @set.sample(5)
      titles.each do |title|
        samples.should have_publication(title)
      end
    end
  end
  
  def have_publication(title)
    simple_matcher("have a title") do |given|
      given.any? { |x| x.publication_title == title }
    end
  end
end