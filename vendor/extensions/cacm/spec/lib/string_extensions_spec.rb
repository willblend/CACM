require File.dirname(__FILE__) + '/../spec_helper'

describe CACM::StringExtensions do
  include CACM::SectionsPathHelper
  
  describe "parameterize" do
    before do 
      # f(x) = y
      @x_strings = []
      @y_strings = []

      # No errors on blanks, right?
      @x_strings << ""
      @y_strings << ""

      @x_strings << "“crazy-quotes”"
      @y_strings << "crazy-quotes"

      @x_strings << "Got data? A guide to data preservation in the information age"
      @y_strings << "got-data-a-guide-to-data-preservation-in-the-information-age"

      @x_strings << "some random <html>in the title</html> that Should be all Stripped"
      @y_strings << "some-random-in-the-title-that-should-be-all-stripped"

      @x_strings << "is it okay if I 'quote' things up here and ask questions?"
      @y_strings << "is-it-okay-if-i-quote-things-up-here-and-ask-questions"

      @x_strings << "what if I like the spacebar lots "
      @y_strings << "what-if-i-like-the-spacebar-lots"

      @x_strings << "will you take questions???"
      @y_strings << "will-you-take-questions"

      @x_strings << "random junk )8383([ ])**'`execute deadly function`'"
      @y_strings << "random-junk-8383-execute-deadly-function"

      # Should chomp off trailing dashes
      @x_strings << "CMI - 15th Computed Maxillofacial Imaging Congress (CMI)"
      @y_strings << "cmi-15th-computed-maxillofacial-imaging-congress-cmi"

      # Should allow international characters to pass
      @x_strings << "CURAC - 8th Annual Meeting of Deutsche Gesellschaft für Computer- und Roboter-Assistierte Chirurgie e.V. (CURAC)"
      @y_strings << "curac-8th-annual-meeting-of-deutsche-gesellschaft-für-computer-und-roboter-assistierte-chirurgie-ev-curac"

      # Leading dashes
      @x_strings << "(CURAC)"
      @y_strings << "curac"
    
      [(33..47),(58..64),(91..96),(123..126)].each do |ranges|
        ranges.each do |ascii|
          @x_strings << ascii.chr+"foo-#{ascii}"
          @y_strings << "foo-#{ascii}"
        end
      end
    end

    it "should strip out things that should be stripped out" do
      @x_strings.each_with_index do |x,i|
        x.parameterize.should eql(@y_strings[i])
      end
    end

    it "should also handle them with an id" do
      @x_strings.each_with_index do |x,i|
        id = rand(1000).to_s
        x.parameterize(id).should eql("#{id}-#{@y_strings[i]}".chomp('-'))
      end
    end
  end

  describe "to_teaser" do
    it "should strip out html" do
      "<html>foo</html>".to_teaser.should eql("foo")
    end

    it "should strip out html with attributes" do
      "<html attribute='present'>bar</html>".to_teaser.should eql("bar")
    end

    it "should truncate to the requested length appending an ending when the number of words exceeds the given length" do
      "The cow jumped over the moon".to_teaser(3).should eql("The cow jumped&nbsp;&hellip;")
    end

    it "should truncate to the requested length not appending an ending when the number of words fails to exceed the given length" do
      "The cow jumped over the moon".to_teaser(10).should eql("The cow jumped over the moon")
    end

    it "should remove trailing punctuation only if the snippet is truncated" do
      "The cow jumped over the moon.".to_teaser(6).should eql("The cow jumped over the moon.")
      "The cow jumped over the moon, and the dish ran away with the spoon.".to_teaser(6).should eql("The cow jumped over the moon&nbsp;&hellip;")
    end

  end

end