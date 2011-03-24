# By Henrik Nyh <http://henrik.nyh.se> 2008-01-30.
# Free to modify and redistribute with credit.

# modified by Dave Nolan http://textgoeshere.org.uk 
# Ellipsis appended to text of last HTML node
# Ellipsis inserted after final word break

# modified by Bennett Kolasinski and Justin Blecher http://digitalpulp.com
# * safeguard against last_child.inner_html being nil
# * truncate along word boundaries (regexp modified from http://vermicel.li/blog/2009/01/30/awesome-truncation-in-rails.html)

require "rubygems"
require "hpricot"

module TextHelper

  # Like the Rails _truncate_ helper but doesn't break HTML tags or entities.
  # This takes the maximum length of the output string in and, if that falls in the middle of a word or entity, truncates to the end
  # of that word / entity.
  def truncate_html(text, max_length = 30, ellipsis = "...")
    return if text.nil?

    doc = Hpricot(text.to_s)
    content_length = doc.inner_text.chars.length
    
    if content_length > max_length
      truncated_doc = doc.truncate(max_length)
      last_child = truncated_doc.children.last
      
      # if the document was truncated
      if truncated_doc.to_s != doc.to_s
        if last_child.inner_html
          last_child.inner_html += ellipsis
        else
          # handle when text doesn't contain any HTML (so there's no last_child)
          truncated_doc.inner_html = truncated_doc.inner_html + ellipsis
        end
      end
      
      truncated_doc.to_s

    else
      # nothing to do here but return
      text
    end
  end
  
end

module HpricotTruncator
  module NodeWithChildren
    def truncate(max_length)

      # return if no truncation necessary
      return self if inner_text.chars.length <= max_length
      truncated_node = self.dup
      truncated_node.children = []
      each_child do |node|
        remaining_length = max_length - truncated_node.inner_text.chars.length
        # since we're chopping on word boundaries here, we might go over the length.
        break if remaining_length <= 0
        truncated_node.children << node.truncate(remaining_length)
      end
      
      truncated_node
    end
  end

  module TextNode
    def truncate(max_length)
      # return the original string if no truncation necessary
      if content.length > max_length
        # the new way, adapted from http://vermicel.li/blog/2009/01/30/awesome-truncation-in-rails.html
        # text = (content[/\A.{#{max_length}}\w*\;?/m][/.*[\w\;]/m]).to_s

        # grab max_length # of chars, plus the rest of the word (including any closing punctutation), 
        # treating entities as one char. note that we're capturing the string up to the max char count
        # to test the char at the boundary to see if it's a space (see below for more).
        text = content[/\A((?:&#?[^\W_]+;|.){#{max_length}})(\w|&#?[^\W_]+;|[\'\"\)\]\}\>])*/m]

        # This shouldn't be the case if we've made it this far, but apparently a nil
        # is slipping through on occasion. Proceed without blowing up.
        return Hpricot::Text.new('') if $1.nil?

        # NOTE: due to the technique used above, the it's possible that the last char desired 
        # will be a space and the result will include an extra word, which we don't want. this 
        # simple test fixes that case and removes the trailing space, too
        text = $1.rstrip if $1[$1.length-1,1] == " "
      else
        text = content
      end
      
      Hpricot::Text.new(text)
    end
  end


  module IgnoredTag
    def truncate(max_length)
      self
    end
  end
end

Hpricot::Doc.send(:include,       HpricotTruncator::NodeWithChildren)
Hpricot::Elem.send(:include,      HpricotTruncator::NodeWithChildren)
Hpricot::Text.send(:include,      HpricotTruncator::TextNode)
Hpricot::BogusETag.send(:include, HpricotTruncator::IgnoredTag)
Hpricot::Comment.send(:include,   HpricotTruncator::IgnoredTag)
