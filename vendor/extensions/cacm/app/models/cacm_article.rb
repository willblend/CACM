class CacmArticle < DLArticle
  
  belongs_to :issue
  before_create :link_to_issue, :set_feed_defaults
  
  acts_as_list :scope => :issue

  def source_human_name
    "From the Digital Library"
  end
  
  def self.retrieve(doi)
    local = super(doi) do |article|
      
      article.feed_id = CACM::CACM_FEED_ID
      # text transform
      if fulltext = article.fetch_dl_data
        # fulltext => [response.body, path]
        
        if article.has_special_markup?
          html = self.parse_october_2002_html(Hpricot(fulltext[0]), fulltext[1])
        else
          html = article.extract_cacm_content(fulltext[0], fulltext[1])
        end
        
        article.full_text = html[:full_text]
        article.leadin = html[:leadin]
        article.toc = html[:toc]
        article.short_description = article.leadin if article.short_description.blank?
      end
    end
    yield local if block_given?
    return local
  end

  def extract_cacm_content(html, path_to_article)
    parse_html(Hpricot(html), path_to_article)
  end
  
  private
  
    def link_to_issue
      @issue = Issue.find_or_create_by_issue_id(source.issue.id)
      @issue.update_attribute(:pub_date, source.issue.pub_date)
      self.issue_id = @issue.id
    end

    def set_feed_defaults
      self.feed_id = CACM::CACM_FEED_ID
      self.news_opinion = self.feed.news_opinion
      self.digital_library = self.feed.digital_library
      self.acm_resource = self.feed.acm_resource
      self.user_comments = self.feed.user_comments
    end

    # NOTE: obviously, the steps in extracting the content from the full-text
    # is highly dependent on the markup structure, and is therefore rather 
    # fragile. CACM DL content seems to be pretty consistently structured 
    # going back to the first full-text HTML piece in ~1999. i'm pretty sure 
    # it's even valid, too!
    # 
    # however, when we extract other content besides that of CACM, we need to 
    # verify the markup structure to determine if we have to extract things 
    # differently. that remains TBD.
    # 
    # NOTE: this method is identical to (and should be kept in sync with) the 
    # parse_html method in the Rake task inside the content_processing folder 
    # at the root of the SVN repo.
    # 
    # FIXME: this feels like it should be a class method, not an instance method.
    def parse_html(old_dom, path_to_article)
      # ToC and lead-in
      # NOTE: ToC may prove to be a problem because it appears in the left-hand column on the page. we may want to do some JS node swapping onDOMReady. ignoring it for now.
      # 1) get children of <ul class="acm">
      # 2) remove lead-in pound-down if present (first LI)
      # 3) get .inner_html of second <p> after <a name="lead-in"></a> if A exists

      toc_node = (old_dom/"ul.acm")[0]
      toc_node.children.reject! { |el| (el/"//a[@href='#lead-in']").length > 0 }

      # the (4) is because of the whitespace nodes in between the element nodes
      # NOTE: the nodes_at method is a bit noisy and outputs some text in the console. weird.
      leadin_node = (old_dom/"//a[@name='lead-in']")
      leadin = leadin_node.length > 0 ? remove_whitespace(leadin_node[0].nodes_at(4).inner_html) : ""

      # journal name
      # 1) get .inner_html of <div class="jrnl">

      journal_name = remove_whitespace((old_dom/".jrnl")[0].inner_html)

      # vol, issue, page #
      # 1) get .inner_html of <div class="iss">

      vol_issue_page = remove_whitespace((old_dom/".iss")[0].inner_html)

      # full-text Anchor / Heading structure (observed)
      # 
      #   lead-in      => extracted
      #   body-1       => kept intact, back-to-top removed
      #   body-n       => kept intact
      #   references   => kept intact
      #   authorinfo   => kept intact
      #   footnotes    => kept intact
      #   figures      => kept intact
      #   tables       => kept intact
      #   sidebar-1    => kept intact
      #   sidebar-n    => kept intact
      #   permission   => kept intact, back-to-top removed

      # "body-n" section headings / back to top look like this:
      # 
      #   <a name="body-3"></a>
      #   <p>
      #   <a href="#top"><img src="http://portal.acm.org/img/arrowu.gif" border="0" alt="back to top">&nbsp;</a>
      #   <b>Moderator</b>
      #   </p>
      # 
      # 1) attempt to find each <a name="body-n"></a> element
      # 2) immediately after element is the P that contains the back to top link and B tag with the section heading
      #    NOTE: body-1 does not have a B tag in the P (i've seen it referenced as "Introduction" or "Article" in the ToC)... remove it.
      # 3) get inner_html of B tag
      # 4) remove P tag
      # 5) insert new back to top link before A tag
      #      <p class="totop"><a href="#PageTop">Back to Top</a></p>
      # 6) insert new Hx tag (with contents of the B tag) after A tag 
      #    NOTE: we may want it in Hx tag, or give the Hx tag the ID of the old A tag and remove the A tag altogether... we'll see

      # known headings look like this:
      # 
      #   <a name="authorinfo"></a>
      #   <p>
      #   <a href="#top"><img src="http://portal.acm.org/img/arrowu.gif" border="0" alt="back to top">&nbsp;</a>
      #   <b>Author</b>
      #   </p>
      # 
      # (same as body-n headings except we replace them with slightly different Hx tags... TBD exactly)

      known_headings = %w(references authorinfo footnotes figures tables permission)
      body_regex = /^body-\d+$/
      sidebar_regex = /^sidebar-\d+$/
      back_to_top = %{<p class="totop"><a href="#PageTop">Back to Top</a></p>\n\n}

      (old_dom/"//a[@name]").each do |anchor|
        next unless known_headings.include?(anchor['name']) || anchor['name'].match(body_regex) || anchor['name'].match(sidebar_regex)

        # the (2) is because of the whitespace nodes in between the element nodes
        p = anchor.nodes_at(2)

        if anchor['name'] == "body-1"
          p.remove

        elsif anchor['name'] == "permission"
          p.remove
          anchor.before(%{<hr class="Separator" />\n})

        else
          heading = remove_whitespace((p/'b')[0].inner_html)
          p.remove
          # put the back-to-top link in between the comments so the soon-to-be-created DIV doesn't wrap it
          anchor.nodes_at(-2).before(back_to_top)
          classname = known_headings.include?(anchor['name']) ? ' class="known-headings"' : ""
          anchor.after(%{\n<h3#{classname}>#{heading}</h3>})
        end
      end
      
      # Fix Article figures and tables
      HtmlMaid.fix_figures_and_tables(old_dom)
      
      # We just gave the figures "back to top" link the wrong class name. Fix:
      (old_dom/".ThumbnailParagraph").each do |thumb_para|
        thumb_para.set_attribute :class, "totop" if thumb_para.inner_text.downcase.eql?("back to top")
      end
      
      # Rewrites URLs and img SRCs to point to deliveryimages.org
      HtmlMaid.change_link_and_img_paths(old_dom, path_to_article)
      
      # final processing
      # 1) body.inner_html
      # 2) remove everything up to <!-- BEGIN BODY-1 -->

      html = (old_dom/:body).inner_html.gsub(/^.+(<!-- BEGIN BODY-1 -->)/m, '\\1')

      # add DIVs around known sections for styling purposes
      # 
      # FIXME: this can probably be optimized by avoiding the ruby interator 
      # and using regexp groups and backreferences to pull out the individual items
      known_headings.each do |heading|
        re = Regexp.new("(<!-- BEGIN #{heading.upcase} -->)(.+)(<!-- END #{heading.upcase} -->)", Regexp::MULTILINE)
        html = html.gsub(re, %{\\1\n<div id="article-#{heading}">\n\\2\n</div>\n\\3})
      end

      # do the same for sidebars, albeit a bit more complicated regex-wise
      html = html.gsub(/(<!-- BEGIN (SIDEBAR-(\d)) -->)\s*(<a name="(sidebar-\3)"><\/a>)(.+)(<!-- END \2 -->)/m, %{\\1\n<div class="ArticleSidebar" id="article-\\5">\n\\4\n\\6\n</div>\n\\7})
      
      # Why don't all tables and figures get a "back to top" link? Not sure, 
      # but let's give it one... unless it's a black sheep that already has one.
      
      # Now we're going to be evil and RE-parse this stuff to safely re-insert
      # some back to top links for figures and tables...
      
      new_dom = Hpricot(html)
      
      # Find the DIVs that are now wrapping the figures and tables. 
      
      figures_div = new_dom.at("#article-figures")
      tables_div = new_dom.at("#article-tables")
      
      if figures_div
        # Don't add double back-to-top links!
        unless figures_div.children_of_type("p").last.get_attribute(:class).eql?("totop")
          # Just to be paranoid, let's also make sure they didn't sneak one in
          # after the wrapping div, either...
          unless figures_div.next_sibling.name.eql?("p") and figures_div.next_sibling['class'].eql?("totop")
            
            # Swap the ENTIRE div for the div + totop link
            # Why can't Hpricot just insert a string after an Hpricot::Elem?
            # ... I'll add that to my hpricot_extensions wish list.
            
            figures_div.swap(figures_div.to_html + '<p class="totop"><a href="#PageTop">Back to top</a></p>')
          end
        end
      end
      
      # Rinse, repeat
      if tables_div
        unless tables_div.children_of_type("p").last.get_attribute(:class).eql?("totop")
          unless tables_div.next_sibling.name.eql?("p") and tables_div.next_sibling['class'].eql?("totop")
            tables_div.swap(tables_div.to_html + '<p class="totop"><a href="#PageTop">Back to top</a></p>')
          end
        end
      end
      
      # OK, back to packaging this up...
      html = new_dom.to_html
      
      return {
        :full_text      => html,
        :leadin         => leadin,
        :journal_name   => journal_name,
        :vol_issue_page => vol_issue_page,
        :toc            => toc_node.inner_html
      }

    ensure
      toc_node = nil
      old_dom = nil
      leadin_node = nil
      GC.start
    end
    
    def self.parse_october_2002_html(old_dom, path_to_article)
      
      old_dom = (old_dom/"body") if (old_dom/"body").any?      
      
      # Kill the top navigation
      (old_dom/".navbar").remove
      
      # Start to clean up the header table
      intro_table = (old_dom/"table").first
      intro_table.swap("") if intro_table
      
      # Next up...
      logo_table = (old_dom/"table").first
      logo_table.swap("") if logo_table
      
      # Try to find the table of contents table
      toc_wrapping_table = (old_dom/"table").first
      contents = []
      if toc_wrapping_table
        toc_table = toc_wrapping_table.search("table").last
        
        toc_table.search("td").each do |td|
          if td.get_attribute(:align) and td.get_attribute(:align).downcase.eql?("left")
            td.swap("") # kill the icon
          else
            contents << "<li>" + td.search("a").first.to_html + "</li>" if td.search("a").first and not td.search("a").first.inner_html.downcase.include?("lead-in")
          end
        end
        
        # Now let's remove this monstrosity!
        toc_wrapping_table.swap("")
      end
      
      HtmlMaid.clean_up_tables(old_dom)
      
      HtmlMaid.kill_font_tags(old_dom)
      
      # Only remove the BR's from the top of the document, leave rest alone
      HtmlMaid.remove_initial_line_breaks(old_dom)
      
      # Rewrites URLs and img SRCs to point to deliveryimages.org
      HtmlMaid.change_link_and_img_paths(old_dom, path_to_article)
      
      figure_anchor = (old_dom/"a[@name=figures]") # try to find the anchor link for figures
      table_anchor = (old_dom/"a[@name=tables]") # table anchor
      
      # start with empty arrays in case all hell breaks loose
      figures = []
      tables = []
      
      unless figure_anchor.empty?
        figures_table = figure_anchor.first.next_sibling # the figures table follows the header
        figures = figures_table.search("p")
      end
      unless table_anchor.empty?
        tables_table = table_anchor.first.next_sibling # The "tables" table
        tables = tables_table.search("p")
      end
      
      figures_and_tables = figures + tables
      
      figures_and_tables.each do |figure|
        
        figure.set_attribute :class, "ThumbnailParagraph"
        figure.search("br").remove
        
        # find the figure image thumbnail
        image = figure.search("img").first
        # find the main, figure image link (not the anchor)
        link = figure.search("a[@href]").first
        
        if image and link # without them we're sort of stuck

          # Dealing with multiple links in Figures/Tables captions
          # See notes in HtmlMaid.rb -amlw 12/17
          if figure.search('a').length > 2
            extra_links = figure.search('a[@href]')
            while extra_links[1]
              extra_links[1].swap("")
              extra_links.delete_at(1)
            end
          end
        
          # remove the janky image styling
          image.remove_attribute :hspace
          image.remove_attribute :vspace
          image.remove_attribute :align
        
          # link for style targeting on links...
          link.set_attribute :class, "ThumbnailLink"
        
          image_extension = image.get_attribute(:src).split(".").last
          new_link = link.get_attribute(:href).sub(/html/, image_extension)
          # change the link href to point directly to the image.
          link.set_attribute :href, new_link.sub("delivery.acm","deliveryimages.acm")
        
          # Grab the image's markup in entirety
          img_markup = image.to_html

          # Grab everything linked, and then remove the image markup. Now link_text
          # is just what will later be the unlinked caption
          link_text = link.inner_html.sub(img_markup, "")

          # Change the link to only contain the image's markup
          link.inner_html = img_markup

          # Now insert the link_text onto the end of the listing paragraph
          figure.inner_html = figure.inner_html + link_text
      
        end
      end
      
      # Now rescue the poor Figures from a floating nightmare.
      (old_dom/"p").each do |para|
        if para.inner_html.include?("/figs/")
          para.set_attribute :style, "clear: left;"
        end
      end
      
      # We just gave the figures "back to top" link the wrong class name. Fix:
      (old_dom/".ThumbnailParagraph").each do |thumb_para|
        thumb_para.set_attribute :class, "totop" if thumb_para.inner_text.downcase.eql?("back to top")
      end
      
      # And fix the tables that are left
      HtmlMaid.correct_inline_widths(old_dom)
      
      
      html = old_dom.inner_html
      leadin = leadin
      journal_name = "" unless journal_name
      vol_issue_page = "" unless vol_issue_page
      toc_node = contents.join("\n")
      
      return {
        :full_text      => html,
        :leadin         => "",
        :journal_name   => journal_name,
        :vol_issue_page => vol_issue_page,
        :toc            => toc_node
      }
      
    end

end