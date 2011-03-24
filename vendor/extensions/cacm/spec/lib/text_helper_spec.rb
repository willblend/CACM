require File.dirname(__FILE__) + '/../spec_helper'

include TextHelper

describe TextHelper do
  
  describe "truncate_html" do
    it "should truncate a string (1)" do
      truncate_html("foof fighter", 4, "...").should eql("foof...")
    end

    it "should truncate a string (2)" do
      truncate_html("foo fighters rock", 11, "...").should eql("foo fighters...")
    end
    
    it "should not truncate a string that's shorter than the max length" do
      truncate_html("foo fighters don't rock", 40, "...").should eql("foo fighters don't rock")
    end
    
    it "shouldn't break nor truncate if the truncation length is less than the first word in the string's length" do
      truncate_html("antidisestablishmentarianism", 5, "...").should eql("antidisestablishmentarianism")
    end

    it "shouldn't break nor truncate if the truncation length is less than the first word in the string's length with HTML" do
      truncate_html("<p>antidisestablishmentarianism</p>", 5, "...").should eql("<p>antidisestablishmentarianism</p>")
    end

    it "should truncate based on the text length, not the ellipsis length" do
      truncate_html("foo fighter", 3, "...").should eql("foo...")      
    end
    
    it "should truncate some html (1)" do
      truncate_html("<p>hello</p>", 5).should eql("<p>hello</p>")
    end

    it "should truncate some html (2)" do
      truncate_html("<p>hello bennett</p>", 5, "...").should eql("<p>hello...</p>")
    end

    it "should truncate some html (3)" do
      truncate_html("<p>hey this is a paragraph.</p><p>this is another paragraph.</p>", 28, "&nbsp;&hellip;").should eql("<p>hey this is a paragraph.</p><p>this&nbsp;&hellip;</p>")
    end

    it "should truncate some html (4)" do
      str = %{<p>this paragraph has a <a href="link">link</a> in it.</p><p>and it is followed by another paragraph.</p>}
      ans = %{<p>this paragraph has a <a href="link">link</a> in it.</p><p>and it&nbsp;&hellip;</p>}
      truncate_html(str, 38, "&nbsp;&hellip;").should eql(ans)
    end

    it "should truncate some html (5)" do
      str = %{<p>this paragraph has a <a href="link">link</a> in it.</p><p>and it is followed by another paragraph.</p>}
      ans = %{<p>this paragraph has a <a href="link">link</a>&nbsp;&hellip;</p>}
      truncate_html(str, 25, "&nbsp;&hellip;").should eql(ans)
    end
    it "should truncate some html (6)" do
      str = %{<p><a href="test"><img src="blah.jpg" />caption</a> testing</p><p>more content here</p><img src="blah.jpg" />}
      ans = %{<p><a href="test"><img src="blah.jpg" />caption</a> testing&nbsp;&hellip;</p>}
      truncate_html(str, 10, "&nbsp;&hellip;").should eql(ans)
    end

    it "should handle malformed html (1)" do
      str = %{<p>hey I'm<a href="meow"> </p> going</a> to write crappy html}
      ans = %{<p>hey I'm<a href="meow"> </a></p> going to&nbsp;&hellip;}
      truncate_html(str, 16, "&nbsp;&hellip;").should eql(ans)
    end

    it "should handle malformed html (2)" do
      str = %{hey I'm </p> going<div> to write crappy html}
      ans = %{hey I'm  going<div> to&nbsp;&hellip;</div>}
      truncate_html(str, 18, "&nbsp;&hellip;").should eql(ans)
    end

    it "should treat entities as one character (1)" do
      truncate_html("<p>hello&nbsp;digital pulp</p>", 10, "&nbsp;&hellip;").should eql("<p>hello&nbsp;digital&nbsp;&hellip;</p>")
    end

    it "should treat entities as one character (2)" do
      str = %{<p>this paragraph&nbsp;has a <a href="link">link</a> in it&hellip;</p><p>and it is followed by another paragraph.</p>}
      ans = %{<p>this paragraph&nbsp;has a <a href="link">link</a> in it&hellip;</p><p>and it&nbsp;&hellip;</p>}
      truncate_html(str, 38, "&nbsp;&hellip;").should eql(ans)
    end

    it "should truncate the string at the correct place (1)" do
      truncate_html("<p>one&nbsp;two thre&eacute;</p>", 13, "&nbsp;&hellip;").should eql("<p>one&nbsp;two thre&eacute;</p>")
    end

    it "should truncate the string at the correct place (2)" do
      truncate_html("<p>one&nbsp;two thre&eacute;</p>", 12, "&nbsp;&hellip;").should eql("<p>one&nbsp;two thre&eacute;</p>")
    end

    it "should truncate the string at the correct place (3)" do
      truncate_html("<p>one&nbsp;two thre&eacute;</p>", 11, "&nbsp;&hellip;").should eql("<p>one&nbsp;two thre&eacute;</p>")
    end

    it "should truncate the string at the correct place (4)" do
      truncate_html("<p>one&nbsp;two thre&eacute;</p>", 10, "&nbsp;&hellip;").should eql("<p>one&nbsp;two thre&eacute;</p>")
    end

    it "should truncate the string at the correct place (5)" do
      truncate_html("<p>one&nbsp;two thre&eacute;</p>", 9, "&nbsp;&hellip;").should eql("<p>one&nbsp;two thre&eacute;</p>")
    end

    it "should truncate the string at the correct place (6)" do
      truncate_html("<p>one&nbsp;two thre&eacute;</p>", 8, "&nbsp;&hellip;").should eql("<p>one&nbsp;two&nbsp;&hellip;</p>")
    end

    it "should truncate the string at the correct place (7)" do
      truncate_html("<p>one&nbsp;two thre&eacute;</p>", 4, "&nbsp;&hellip;").should eql("<p>one&nbsp;two&nbsp;&hellip;</p>")
    end

    it "should deal with multibyte characters and the dreaded smart quotes with ease (1)" do
      str = %{she said to me, <em>“¿Qué pasa contigo?”</em> and I said— <h1>nothing</h1>.}
      ans = %{she said to me, <em>“¿Qué pasa&nbsp;&hellip;</em>}
      truncate_html(str, 24, "&nbsp;&hellip;").should eql(ans)
    end

    it "should deal with multibyte characters and the dreaded smart quotes with ease (2)" do
      str = %{she said to me, <em>“¿Qué pasa contigo?”</em> and I said— <h1>nothing</h1>.}
      ans = %{she said to me, <em>“¿Qué pasa contigo?”</em> and I said—&nbsp;&hellip;}
      truncate_html(str, 46, "&nbsp;&hellip;").should eql(ans)
    end

    it "should deal with multibyte characters and the dreaded smart quotes with ease (3)" do
      str = %{she said to me, <em>“¿Qué pasa contigo?”</em> and I said— <h1>nothing</h1>.}
      ans = %{she said to me, <em>“¿Qué pasa contigo?”</em> and I said— <h1>nothing&nbsp;&hellip;</h1>}
      truncate_html(str, 53, "&nbsp;&hellip;").should eql(ans)
    end

    it "should retain closing entities if they're at the end of the last word of the truncated phrase (1)" do
      str = "<p>so this (I think) is what you want?</p>"
      ans = "<p>so this (I think)&nbsp;&hellip;</p>"
      truncate_html(str, 13, "&nbsp;&hellip;").should eql(ans)
    end

    it "should retain closing entities if they're at the end of the last word of the truncated phrase (2)" do
      str = "<p>so this (I think) is what you want?</p>"
      ans = "<p>so this (I&nbsp;&hellip;</p>"
      truncate_html(str, 10, "&nbsp;&hellip;").should eql(ans)
    end

    it "should retain closing entities if they're at the end of the last word of the truncated phrase (3)" do
      str = "<p>\"hey now\" is what you want?</p>"
      ans = "<p>\"hey now\"&nbsp;&hellip;</p>"
      truncate_html(str, 7, "&nbsp;&hellip;").should eql(ans)
    end

    it "should not retain punctuation after the last word if the phrase is truncated" do
      str = "<p>what do you think? I don't like it much.</p>"
      ans = "<p>what do you think&nbsp;&hellip;</p>"
      truncate_html(str, 13, "&nbsp;&hellip;").should eql(ans)
    end

  end
end