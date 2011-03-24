# HTML Maid
# cleans up your HTML from feeds, leaves mint on pillow
class HtmlMaid
  
  class << self
    
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::TextHelper
    
    # returns true if the first tag in 'html' is a block element
    def first_tag_is_a_block_tag(html)
      blockelems = ["P", "H1", "H2", "H3", "H4", "H5", "H6", "OL", "UL", "PRE", "DL", "DIV", "NOSCRIPT", "BLOCKQUOTE", "FORM", "HR", "TABLE", "FIELDSET", "ADDRESS"]
      r = /<(\w+).*>/
      res = r.match(html)
      if res.nil?
        false
      else
        blockelems.include?(res[1].upcase) ? true : false
      end
    end
    
    # strip any unwanted bits from the HTML
    def housekeeping(html)
      h = Hpricot(html)
      # feedflare: buh-bye
      h.search("div.feedflare").remove
      # 1x1 tracking images: ciao
      #h.search("/img[@height='1'][@width='1']").remove
      h/"img[@src^=http://feeds.feedburner]"
      # return un-dirty HTML
      h.to_html
    end
    
    # clean up the short description - remove any images & BRs and clean up with hpricot
    def clean_short_description(snippet)
      # Hpricot.parse raises an ArgumentError when passed nil
      snippet.nil? ? return : h = Hpricot.parse(snippet)
    
      # Remove Images
      h.search("img").collect! { |node|

        # go up until your parent node is the root node or the node has some inner_text. then prune.
        until node.parent.is_a?(Hpricot::Doc) || !node.parent.inner_text.empty? do
          node = node.parent
        end

        node
      }.compact.remove
    
      # Remove BR's
      h.search("br").remove
    
      h.to_html # return the markup
    end

    ##########################################################################
    
    # Processing helpers for importing non-CACM DL Articles

    def remove_whitespace(str="")
      str.strip.gsub(/\s+/, " ")
    end

    # This is an initial hitlist that clears out a lot of junk that we don't want.
    def remove_forbidden_elements(hpricot_dom)

      (hpricot_dom/"head").remove # head element
      (hpricot_dom/"#banner").remove # header layout
      (hpricot_dom/"center").remove # extra titles and junk
      (hpricot_dom/"h1").remove # title
      (hpricot_dom/"#footerlinks").remove # footer
      (hpricot_dom/"script").remove # google analytics
      (hpricot_dom/"form").remove # search forms
      (hpricot_dom/".w3cbutton3").remove # bye, hat-tips to the W3C
      (hpricot_dom/".iss").remove # issue, stashed already
      (hpricot_dom/".jrnl").remove # journal, already known

      # Remove certain tables used for layouts and contents
      (hpricot_dom/"table[@summary]").each do |table|
        summary = table.get_attribute :summary
        table.swap("") if summary.include?("Title") or summary.include?("Table")
      end

      # Remove header graphic
      (hpricot_dom/"img").each do |pic|
        pic.swap("") if pic.get_attribute(:src).include?("logo")
      end

      # Insert a "back to top" anchor for them to link to, and remove the first
      # top anchor because it's right at the top now that we removed the header stuff.
      hpricot_dom.inner_html = "<a style=\"display:none;\" id=\"top\"></a>" + hpricot_dom.inner_html
      (hpricot_dom/"a[@href='#top']").first.swap("") rescue nil # just in case it's MIA
      
      # Strip out bad characters
      hpricot_dom.inner_html = hpricot_dom.inner_html.chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').to_s
      
      # Correct sloppy tags
      hpricot_dom.inner_html = hpricot_dom.inner_html.squeeze(">").squeeze("<")

      return hpricot_dom
    end

    # This takes care of the final pieces, like comments that we've already used
    # to determine sections, but are now ready for removal, or other elements that
    # are useful during the cleanup but shouldn't make it to the final product.
    def final_cleanup(hpricot_dom)

      # Remove comments, which were old includes commented out god knows when
      (hpricot_dom/"//comment()").remove

      return hpricot_dom  
    end

    # A lot of these articles use tables for structuring layout, usually meaning
    # that the navigation is hanging out to the left, pushing the content out of
    # sight. Also, some times they have "border" TRs that just push our content
    # off by a few more pixels. Kill every TD that didn't get > 25% of layout or > 225px

    # And once we do that, let's go over them once more to make sure we don't have
    # any sub-tables with widths < 225, and also remove any empty TD's, which is a
    # likely result of killing tables + table content.

    def clean_up_tables(hpricot_dom)

      # Fix the smaller TDs
      (hpricot_dom/"td[@width]").each do |td|
        width = td.get_attribute :width
        if width.include?("%") # calculated by percent
          td.swap("") if width.to_i < 25
        else # calculated by pixels
          td.swap("") if width.to_i < 225
        end
      end

      # Fix the smaller sub tables
      (hpricot_dom/"table[@width]").each do |table|
        width = table.get_attribute :width
        if width.include?("%") # calculated by percent
          table.swap("") if width.to_i < 25
        else # calculated by pixels
          table.swap("") if width.to_i < 225
        end
      end

      # Now clean up any empty TDs
      (hpricot_dom/"td").each do |td|
        td.swap("") if td.inner_text.strip == ""
      end

      # Now, one more pass over the tables
      (hpricot_dom/"table").each do |table|
        table.swap("") if table.inner_text.strip == ""
      end

      return hpricot_dom
    end

    # Remove inline styling from DIVs and TABLEs, mostly to avoid inline styling of
    # widths greater than our main column. But if some other inline styles get wiped
    # out, well, all the better!
    def correct_inline_widths(hpricot_dom)

      (hpricot_dom/"div[@style]").each do |div|
        div.set_attribute :style, ""
      end

      (hpricot_dom/"table[@width]" + hpricot_dom/"td[@width]").each do |table|
        table.set_attribute :width, "100%"
      end

      return hpricot_dom
    end

    # Remove all font tags from inner_html
    def kill_font_tags(hpricot_dom)
      hpricot_dom.inner_html = hpricot_dom.inner_html.gsub(/<\/?[Ff][Oo][Nn][Tt].*>/,"")
    end
    
    # We know this drill: spans with class MsNormalOfficeBS, or lang attributes
    # or just weird styles that clash horribly (I offer the example of an
    # unclosed span with "font-family:Wingdings" as humble tribute to the 
    # altar of worst markup in the world)
    def kill_span_tags(hpricot_dom)
      hpricot_dom.inner_html = hpricot_dom.inner_html.gsub(/<\/?[Ss][Pp][Aa][Nn].*>/,"")
    end

    # Some articles are very sloppy with their B's and I's and it winds up 
    # mangling the entire article in a giant bold style or something equally bad.
    # This also prohibits us from being able to make sense of the document, since
    # everything is stuck in a freaking B or I tag. Grrr. Mostly for older articles.
    def remove_old_styling_elements(hpricot_dom)

      html = hpricot_dom.inner_html
      html = html.gsub(/<\/?b>/,"")
      html = html.gsub(/<\/?i>/,"")
      hpricot_dom.inner_html = html

    end

    # No, seriously, we are NOT letting some punk registration callout mess up
    # our entire layout with a big promotional registration image or link!
    def remove_promotional_callouts(hpricot_dom)
      ((hpricot_dom/"ul") + (hpricot_dom/"a")).each do |potential_promotion|
        html = potential_promotion.to_html
        if html.include?("signup.acm.org") or html.include?("Forums") or html.include?("Past Issues") or html.include?("joinacm")
          potential_promotion.swap("") # begone!
        end
      end
    end
    
    # Rewrites URL and image SRCs to complete their relative path
    def change_link_and_img_paths(dom, path)
      
      # First we get the correct path...
      path = path.split("/")[0..-2].join("/")
      
      # And we build the image path, which can go directly to deliverimages.acm...
      image_path = path.sub('delivery.','deliveryimages.')
      
      # Find images
      (dom/"img").each do |image|
        src = image.get_attribute :src
        unless src.include?("http") # leave properly pointed images alone
          image.set_attribute :src, image_path + "/" + src # append relative src to path
        end
      end
      
      # Find links
      (dom/"a").each do |link|
        href = link.get_attribute :href
        
        unless href.nil?
          
          # again, leave good links and anchors alone
          unless href.starts_with("\#") or href.starts_with("http") or href.starts_with("/") or href.include?("www.")
            link.set_attribute :href, path + "/" + href
            
            if href.include?('gif') or href.include?('jpg') or href.include?('png') or href.include?('jpeg')
              link.set_attribute :href, link.get_attribute(:href).sub('delivery.','deliveryimages.')
            end
            
          end
          
        end
      end
      
    end
    
    # remove LIs that are hanging out outside of UL/OLs.
    def destroy_invalid_list_items(hpricot_dom)
      (hpricot_dom/"li").each do |list_item|
        list_item.swap("") unless list_item.parent.name.downcase.eql?("ul") or list_item.parent.name.downcase.eql?("ol")
      end
    end
    
    # So apparently people used to think ULs and OLs were just a handy
    # div-like place to drop some B and P tags that might resemble a "list"
    # or perhaps some a list-like contraption. If we're dealing with one of
    # these atrocities in markup, we need to just cut the cord. You're not
    # allowed to use ULs or OLs in such poor manner.
    def destory_invalid_list_containers(hpricot_dom)
      ((hpricot_dom/"ul") + (hpricot_dom/"ol")).each do |potential_list|
        list_children = potential_list.children.collect { |x| x.elem? ? x : nil }.compact.map(&:name).uniq
        if list_children.length > 1 or not list_children.first.eql?("li")
          hpricot_dom.inner_html = hpricot_dom.inner_html.gsub(/<[oul][il].*>/,"<div>")
          hpricot_dom.inner_html = hpricot_dom.inner_html.gsub(/<\/[oul][il].*>/,"</div>")
        end
      end
    end
    
    # We can't reliably just nuke all the BRs in a text (as much as I'd enjoy
    # that...) - but we can at least destroy the ones that are stacking up
    # line breaks to ruin the article flow.
    def remove_stacked_line_breaks(hpricot_dom)
      (hpricot_dom/"br").each do |linebreak|
        linebreak.swap("") if linebreak.next_sibling and linebreak.next_sibling.name.eql?("br")
      end
      # And, for good measure, remove any BR at the top of a paragraph tag
      hpricot_dom.inner_html = hpricot_dom.inner_html.gsub(/(<p.*>)\s*<br \/>/, "<p>")
    end
    
    def fix_figures_and_tables(old_dom)
      # Fix Article Figures & Tables
      
      figures = [] # for collecting the listings
      tables = []
      
      figure_anchor = (old_dom/"a[@name=figures]") # try to find the anchor link for figures
      unless figure_anchor.empty?
        next_figure = figure_anchor.first.next_node # start at the top of the figure listings, following anchor header
        # iterate over figure listings (P's) until we get to either a separator, or an anchor for the next section
        while next_figure and not (next_figure.elem? && next_figure.name == "a")
          figures << next_figure if next_figure.elem? && next_figure.name == "p"
          next_figure = next_figure.next_node
        end
      end
      
      table_anchor = (old_dom/"a[@name=tables]") # try to find the anchor link for tables
      unless table_anchor.empty?
        next_table = table_anchor.first.next_node # start at the top of the table listings
        # iterate over the potential table P's
        while next_table and not (next_table.elem? && next_table.name == "a")
          tables << next_table if next_table.elem? && next_table.name == "p"
          next_table = next_table.next_node
        end
      end
      
      figures_and_tables = figures + tables

      figures_and_tables.each_with_index do |listing, index|

        # Give the containing paragraph a class name for later style targetting
        listing.set_attribute :class, "ThumbnailParagraph"

        # kill the BRs
        listing.search("br").remove

        # find the figure image thumbnail
        image = listing.search("img").first
        # find the main, figure image link (not the anchor)
        link = listing.search("a[@href]").first
        
        if image and link # without them we're sort of stuck
          
          # Dealing with multiple links in Figures/Tables captions
          # Some articles have the article thumbnail, and then a caption, and
          # then AFTER the caption they start to reference ANOTHER caption,
          # including the anchor href and sometimes an extra link to the other
          # picture. Helpful but impossible to predict, and therefore it must
          # sleep with the fishes. -amlw 12/17
          if listing.search('a').length > 2
            extra_links = listing.search('a[@href]')
            while extra_links[1]
              extra_links[1].swap("")
              extra_links.delete_at(1)
            end
          end
          
          # remove the janky image styling
          image.remove_attribute :hspace
          image.remove_attribute :vspace
          image.remove_attribute :align
          
          # give the image link a class to target with styling
          link.set_attribute :class, "ThumbnailLink"
          
          # grab the correct image extension for the image link
          image_extension = image.get_attribute(:src).split(".").last
          new_link = link.get_attribute(:href).sub(/html/, image_extension)
          # change the link href to point directly to the image.
          link.set_attribute :href, new_link
          
          # images pointing to delivery.acm will be changed to deliveryimages.acm later on in process
          
          # Grab the image's markup in entirety
          img_markup = image.to_html

          # Grab everything linked, and then remove the image markup. Now link_text
          # is just what will later be the unlinked caption
          link_text = link.inner_html.sub(img_markup, "")

          # Change the link to only contain the image's markup
          link.inner_html = img_markup

          # Now insert the link_text onto the end of the listing paragraph
          listing.inner_html = listing.inner_html + link_text

          # Note: It has to happen in this order, and without relying on inner_text
          # or we run into complications with inner_text removing HTML entities during
          # the transformation while inner_html preserves the HTML entities --
          # which results in double captions, one linked, one not. Boo. -amlw 2/16
          
        end
      end
    end
    
    def remove_initial_line_breaks(hpricot_dom)
      
      if hpricot_dom.first 
        # do we have a containing element (e.g. body)
        # if so, we want to go through each part of the top of the dom
        # until we find actual content, and remove all BRs along the way
        
        content_is_found = false
        hpricot_dom.first.containers.each do |node|
          unless content_is_found
            if node.name.eql?("br")
              node.swap("") # remove br
            elsif ["table","p"].include?(node.name)
              content_is_found = true # okay, the content started
              sub_content_is_found = false # but it might be hidden further!
              if node.name.eql?("table")
                if td = node.search('td').first
                  td.containers.each do |subnode|
                    unless sub_content_is_found
                      if subnode.name.eql?("br")
                        subnode.swap("") # remove br
                      else
                        sub_content_is_found = true
                      end
                    end
                  end
                end
              elsif node.name.eql?("p")
                node.children.each do |subnode|
                  unless sub_content_is_found
                    if subnode.name && subnode.name.eql?("br")
                      subnode.swap("")
                    elsif subnode.class.eql?(Hpricot::Text)
                      sub_content_is_found = true
                    end
                  end
                end
              end
            end
          end
        end
        
      end
      
    end
    
  end
end