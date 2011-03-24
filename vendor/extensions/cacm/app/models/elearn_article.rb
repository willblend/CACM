class ELearnArticle < DLArticle
  
  def source_human_name
    "From eLearn Article"
  end
  
  
  def self.retrieve(doi)
    local = super(doi) do |article|

      article.feed_id = CACM::DL_FEED_ID
      # text transform
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
    ELearnArticle.parse_html(Hpricot(html), path_to_article)
  end
  
  class << self
    def parse_html(old_dom, path_to_article)
      
      old_dom = (old_dom/"body").first if (old_dom/"body").any?

      # Kill the logo
      old_dom.search("img").each do |img|
        img.swap("") if img.get_attribute(:src).include?("logo")
      end

      # Remove header tables
      old_dom.search("table").each do |table|
        table.swap("") if table.get_attribute(:summary) and ( table.get_attribute(:summary).include?("logo") or table.get_attribute(:summary).include?("listing") )
      end

      # Kill the journal name
      (old_dom/".jrnl").remove

      # Stash the volume, then remove it
      volume = (old_dom/".iss").inner_text.strip rescue nil
      (old_dom/".iss").remove

      # Find the TOC, extract, remove from body
      toc_list = (old_dom/".acm")
      if toc_list.any?
        toc_list = toc_list.first
        toc_node = toc_list.inner_html
        (old_dom/"table").collect!{ |t| t.get_attribute(:summary) and t.get_attribute(:summary).include?("Contents") ? t : nil }.compact.remove
      else
        toc_node = nil
      end

      # Add block to headers so they can live next to the back-to-top links
      # And remove the first one.
      old_dom.search("a[@href=#top]").each_with_index do |anchor, index|
        if index.eql?(0)
          anchor.swap("")
        elsif anchor.next_sibling and anchor.next_sibling.name.eql?("b")
          # The next sibling is the subheading
          anchor.next_sibling.set_attribute(:style, "display:block;")
        end
      end

      # Clean up br's
      old_dom.search("br").remove
      
      # Fix any URLs
      HtmlMaid.change_link_and_img_paths(old_dom, path_to_article)

      journal_name = "eLearn"
      html = old_dom.to_html
      vol_issue_page = volume || ""

      return {
        :full_text      => html,
        :journal_name   => journal_name,
        :vol_issue_page => vol_issue_page,
        :toc            => toc_node
      }
      
    end
  end
end