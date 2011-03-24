class NetworkerArticle < DLArticle
  
  def source_human_name
    "From Networker"
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
    NetworkerArticle.parse_html(Hpricot(html), path_to_article)
  end

  class << self
    def parse_html(old_dom, path_to_article)
      
      if (old_dom/"body").any?
        old_dom = (old_dom/"body").first
      end

      # Grab the issue page
      if (old_dom/".iss").any?
        vol_issue_page = (old_dom/".iss").first.inner_text
        (old_dom/".iss").remove
      else
        vol_issue_page = ""
      end

      # Grab the table of contents
      if (old_dom/".acm").any?
        toc_node = (old_dom/".acm").inner_html
        (old_dom/".acm").remove
      else
        toc_node = nil
      end

      # Remove the Journal title
      journal_name = "netWorker"
      (old_dom/".jrnl").remove

      # Remove Title / table of contents tables from headers
      (old_dom/"table[@summary]").each do |table|
        summary = table.get_attribute :summary
        table.swap("") if summary.include?("Title") or summary.include?("Table")
      end

      # Insert a "back to top" anchor for them to link to, and remove the first
      # top anchor because it's right at the top now that we removed the header stuff.
      old_dom.inner_html = "<a style=\"display:none;\" id=\"top\"></a>" + old_dom.inner_html
      (old_dom/"a[@href='#top']").first.swap("") rescue nil # just in case it's MIA

      # Rip out the header graphic
      (old_dom/"img").each do |pic|
        pic.swap("") if pic.get_attribute(:src).include?("logo")
      end
      
      # Take out the "back to top" links when they're tucked into a header that
      # isn't actually a header, but a B tag.
      (old_dom/"a[@href=#top]").each do |anchor|
        anchor.swap("") if anchor.next_sibling and anchor.next_sibling.name.eql?("b")
      end
      
      # Remove BRs
      (old_dom/"br").remove
      
      html = old_dom.inner_html

      return {
        :full_text      => html,
        :journal_name   => journal_name,
        :vol_issue_page => vol_issue_page,
        :toc            => toc_node
      }
      
    end
  end
  
end