class CrossroadArticle < DLArticle
  
  def source_human_name
    "From Crossroads"
  end
  
  def self.retrieve(doi)
    local = super(doi) do |article|
      article.feed_id = CACM::DL_FEED_ID
      if fulltext = article.fetch_dl_data
        # fulltext => [response.body, path]
        html = article.extract_content(fulltext[0], fulltext[1])
        article.full_text = html[:full_text]
        article.toc = html[:toc]
      end
      
      article.leadin = article.source.abstract ? article.source.abstract : ""
      article.short_description = article.leadin
      
    end
    yield local if block_given?
    return local
  end
  
  
  def extract_content(html, path_to_article)
     CrossroadArticle.parse_html(Hpricot(html), path_to_article)
  end

  class << self
    def parse_html(html, path_to_article)
      
      html = (html/"body").first if (html/"body").any?
      
      HtmlMaid.remove_forbidden_elements(html)
      HtmlMaid.kill_font_tags(html)
      HtmlMaid.kill_span_tags(html)
      HtmlMaid.remove_old_styling_elements(html)
      HtmlMaid.clean_up_tables(html)
      HtmlMaid.correct_inline_widths(html)
      HtmlMaid.remove_promotional_callouts(html)
      HtmlMaid.remove_stacked_line_breaks(html)
      
      # Fix References DLs
      (html/"h2").each do |header|
        if header.inner_text.include?("References") and header.next_sibling and header.next_sibling.name.eql?("dl")
          # found our Reference list! Now let's do a little styling for the DTs...
          header.next_sibling.search("dt").each { |dt| dt.set_attribute :style, "float: left; display: block; padding-right: .5em;" }
        end
      end
      
      # Ditch some Crossroads-specific junk
      (html/"a").each do |link|
        if href = link.get_attribute(:href) and not href.blank?
          link.swap("") if href.include?("copyright.html") or href.include?("w3.org")
        end
      end
      
      HtmlMaid.change_link_and_img_paths(html, path_to_article)
      
      full_text = html.inner_html
      
      journal_name = "Crossroads"
      vol_issue_page = ""
      
      return {
        :full_text => full_text,
        :leadin         => leadin,
        :journal_name   => journal_name,
        :vol_issue_page => vol_issue_page,
        :toc            => nil
      }
      
    end
    
  end

end