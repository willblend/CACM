module CACM
  module StringExtensions
    
    require 'htmlentities'

    # parameterize operates on strings and takes an optional ID parameter
    # its primary purpose is to turn article titles into SEO and user friendly
    # slugs by stripping out problematic characters and html, downcasing, and 
    # replacing spaces with dashes. When given an ID it prepends it to modified string
    def parameterize(id=nil)
      # Prepare the ID portion or blank it
      id = id.blank? ? "" : "#{id}-"

      # Remove HTML
      slug = self.downcase.strip.gsub(/<(.|\n)*?>/,'')
      
      # Decode HTML Entities
      # &ldquo; => “ (smart quotes)
      slug = HTMLEntities.new.decode(slug)
      
      # Clean weird characters, and weird win1252 character set conversions
      slug = slug.gsub("\342\200\230",'') # single quote
      slug = slug.gsub("\342\200\231",'') # single quote
      slug = slug.gsub("\342\200\234",'') # double quote
      slug = slug.gsub("\342\200\235",'') # double quote
      slug = slug.gsub("\342\200\224",'') # mdash
      slug = slug.gsub(/[\240]/,'-') 
      slug = slug.gsub(/[\…\–\/]/,'-') # Convert some characters into dashes
      
      # Remove some common weird characters
      slug = slug.gsub(/[\©\®\!\@\#\$\%\^\&\*\?\+\=\:\;\<\>\[\]\{\}\~\|\\\_\,\`\'\"\.\(\)]/,'')
      
      # Remove leading dashes
      slug = slug[0..0].eql?("-") ? slug[1..-1] : slug

      # Join the portions, and replace non-word (+i18n) characters with dashes
      # Squeeze runs of dashes, chomp off trailing dashes, and present
      (id+slug).gsub(/[^\w]/, '-').squeeze('-').chomp('-')
    end

    # the to_teaser method operates on a string, returning a new string which is truncated to 
    # the specified or default number of words. When the original strings word count exceeds 
    # the truncated word count a space and ellipsis (...) is added
    def to_teaser(length=20)
      # Remove HTML
      cleaned = gsub(/<\/?[^>]*>/, "").split(" ")

      # If the given string is over the given length at the `...' punctuation otherwise leave as is
      if (cleaned.size > length)
        # Join it, chomp off trailing `.'s and `,'s and at the ending
        cleaned[0..(length-1)].join(" ").chomp(".").chomp(",") + "&nbsp;&hellip;"
      else
        cleaned.join(" ")
      end
            
    end
    
    # The FCK Cleanup is responsible for converting known characters that the FCK WYSIWYG Editor tends to introduce
    # Please do not modify this method for any reason as all page, snippet, and widget content passes through this 
    # method on its way to the database.

    def fck_cleanup
      # Change the following from their named entity to their decimal entity
      gsub!("&nbsp;","&#160;")
      gsub!("&amp;","&#38;")

      # Turn &apos; back into `'`  because IE6 is a "special" browser
      gsub!("&apos;","'")

      # get rid of line breaks that sneak into top of wysiwyg
      gsub!(/\A<p>&#160;<\/p>[\s]*/,'')
    
      # get rid of fck's wrapping paragraphs around block elements
      while match = self.match(/^<p>[\s]*<(div|table|ul|ol|dl|p|h1|h2|h3|h4|h5|h6)/)
        gsub!(/^<p>[\s]*<#{match[1]}/, "<#{match[1]}")
        gsub!(/<\/#{match[1]}>[\s]*<\/p>/, "</#{match[1]}>")
      end
    
      return self
    end
    
    # Used enough to merit a helper
    def underscorize
      self.gsub(" ","_")
    end

  end
end