require "xml/libxml"
require "libxml"

class Widget < ActiveRecord::Base
  class WidgetReplaceError < StandardError; end
  class WidgetMissingPropertiesError < StandardError; end
  
  validates_presence_of :name, :content
  validates_uniqueness_of :name

  attr_accessor :fck_content, :rtag_abstracts, :rtag_blocks, :error_for_flash
  
  def widgetize
    # LibXML is finicky and will not parse malformed content
    # it also complains about tags nested with attributes of other tags
    # which is why we have html being output by some radius tags
    begin
      # Define the `r' namespace and wrap the content in a block level tag, then parse
      parsed = LibXML::XML::Parser.string("<widget xmlns:r=\"http://www.r.com/r/1.0/\">"+(content || "")+"</widget>").parse

      # Stores metadata about attributes a radius tag can have, and how to render them in a form
      matched_tags = Hash.new

      # Stores copies of the removed radius blocks
      radius_blocks = Hash.new

      # Iterate over the parsed content's radius tags
      parsed.find('//r:*').each_with_index do |rtag,index|
        # Look for a properties attribute to give to the replacement image
        if !!rtag["properties"]
          insert = LibXML::XML::Node.new('img')
          # Duplicate the properties attribute attributes
          insert["style"] = rtag["properties"]
          insert["src"] = "/images/grey.gif"
          insert["alt"] = "widget replacement"
          # Flag this so we can match the image to a particular radius block on the flip side
          insert["id"] = "fck-widget-#{index}"
          # Insert the insert, true => deep clone
          rtag.next = insert.copy(true)
          # Copy the radius block
          radius_blocks[index] = rtag.copy(true)
          # Pop out the radius block
          rtag.remove!
        end

        # Tag Descriptions are stored in the widget_tags.rb / radius_tags.rb
        # They are located above the tag definition in the desc block
        # Page.tag_descriptions lets us access them, we load them into YAML
        matched_tags[rtag.name] = YAML.load(Page.tag_descriptions[rtag.name])["attributes"] if Page.tag_descriptions[rtag.name]
        if matched_tags[rtag.name]
          # There can be several attributes ( limit = 4, section = 2, etc. ) 
          # on a radius tag, so iterate over them
          matched_tags[rtag.name].each_pair do |name,form_props|
            # If there is a current value on the widget take it, otherwise blank it
            matched_tags[rtag.name][name]["value"] = rtag[name] || ""
          end
        end
      end

      # Dump the <widget xmlns:r="...">...</widget> wrapper
      self.fck_content = parsed.root.child.to_s

      # Are there still radius tags there? There shouldn't be
      raise WidgetMissingPropertiesError, "There are Radius Tags at the root level without properties defined" if fck_content.match(/<\/?r:/)

      # Set the accessors
      self.rtag_abstracts = matched_tags
      self.rtag_blocks = radius_blocks

      return true

    rescue LibXML::XML::Parser::ParseError, LibXML::XML::Error, ParseError, WidgetMissingPropertiesError => e
      # This catches known, predictable problems such as bad markup
      # If there is a different exception it will not be caught here and 
      # should be investigated and perhaps added to this or another block
      self.error_for_flash = "This widget appears to have bad markup. <br /> #{e}"
      return false

    ensure
      # Garbage Collect as advised by various library authors
      parsed = nil ; GC.start

    end
  end
  
  def dewidgetize
    begin
      # Define the `r' namespace and wrap the incoming fck_content in a block level tag, 
      # remove fck weirdness - there may need to be additions made here, and finally parse
      parsed = LibXML::XML::Parser.string("<widget xmlns:r=\"http://www.r.com/r/1.0/\">"+(fck_content||content).fck_cleanup+"</widget>").parse

      # How many rtag_blocks are there? Check the accessor or 0 if there are none
      blocks = (rtag_blocks || []).size

      # Iterate over all images
      parsed.find('//img').each_with_index do |img,index|
        # But we only care about ones with an alt of `widget replacement' 
        if !!img["alt"] && img["alt"].eql?("widget replacement")
          # Find the cooresponding radius block by parsing the images id (which has the flag)
          insert = LibXML::XML::Parser.string(rtag_blocks[img["id"].split('-').last]).parse.root

          # If they adjusted the properties of the grey image 
          # (height / width) copy that back over for next time
          insert["properties"] = img["style"]

          # Put back the Radius block, deep clone
          img.next = insert.copy(true)
          
          # Kill the image
          img.remove!

          # Down the count
          blocks -= 1
        end
      end

      # There should be the same number of images with an alt of 'widget replacement'
      # as there are radius blocks. Otherwise they likely deleted an image, so raise an error
      raise WidgetReplaceError, "You may not erase the grey images" unless blocks.eql?(0)

      # We now have a restore copy of the widgets content. All we have to do now 
      # is copy any attributes the user defined through the form abstracts.
      # Iterate over all the radius tags
      parsed.find('//r:*').each do |rtag|
        # Are there tag abstracts? Is there one for this radius tag?
        if rtag_abstracts && rtag_abstracts[rtag.name]
          # For every attribute for this tag, copy the attribute and the value
          rtag_abstracts[rtag.name].each do |attribute,value|
            rtag[attribute] = value
          end
        end
      end

      # Again, remove the widget namespace wrapper. LibXML likes to add the xmlns 
      # definition all up and down this piece. So gsub for it after it becomes a string
      forAR = parsed.root.child.to_s.gsub(/ xmlns:r=\"http:\/\/www.r.com\/r\/1.0\/\"/,'')

      # Set it
      self.content = forAR

      return true

    rescue WidgetReplaceError => e
      self.error_for_flash = "Your Widget could not be saved! <br /> #{e}"
      return false

    rescue ParseError, LibXML::XML::Error => e
      self.error_for_flash = "This widget appears to have bad markup, please fix it and try again #{e}"
      return false

    ensure
      # Garbage Collect
      parsed = nil ; GC.start
    end
  end

end