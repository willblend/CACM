class UbiquityArticle < DLArticle
  
  def source_human_name
    "From Ubiquity"
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
    UbiquityArticle.parse_html(Hpricot(html), path_to_article)
  end

  class << self
    def parse_html(old_dom, path_to_article)
      
      HtmlMaid.remove_forbidden_elements(old_dom)
      HtmlMaid.kill_font_tags(old_dom)
      HtmlMaid.kill_span_tags(old_dom)
      HtmlMaid.remove_old_styling_elements(old_dom)
      HtmlMaid.clean_up_tables(old_dom)
      HtmlMaid.correct_inline_widths(old_dom)
      HtmlMaid.remove_promotional_callouts(old_dom)
      HtmlMaid.destroy_invalid_list_items(old_dom)
      HtmlMaid.destory_invalid_list_containers(old_dom)
      HtmlMaid.remove_stacked_line_breaks(old_dom)
      
      # remove line breaks
      (old_dom/"br").remove
      
      # try to grab the html element
      old_dom.inner_html = (old_dom/"html").first.inner_html if (old_dom/"html").any?
      
      # grab body element, in case it's an older version
      old_dom = (old_dom/"body").first if (old_dom/"body").any?
      
      # Find the header P and remove it
      (old_dom/"a").collect! { |a| a.get_attribute(:href) and a.get_attribute(:href).match(/www\.acm\.org\/?$/) ? a : nil }.compact.each { |a| a.parent.swap("") }
      
      html = old_dom.inner_html
      journal_name = "Ubiquity"
      vol_issue_page = ""

      return {
        :full_text      => html,
        :journal_name   => journal_name,
        :vol_issue_page => vol_issue_page,
        :toc            => nil
      }
      
    end
  end
  
end