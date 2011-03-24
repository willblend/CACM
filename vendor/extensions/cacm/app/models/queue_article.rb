class QueueArticle < DLArticle
  
  def source_human_name
    "From Queue"
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
    QueueArticle.parse_html(Hpricot(html), path_to_article)
  end

  class << self
    def parse_html(old_dom, path_to_article)
      
      # The Queue markup is great. Just grab the body and call it a day.

      if (old_dom/"body").any?
        old_dom = (old_dom/"body").first
      end
      
      # Fix inline image SRCs
      HtmlMaid.change_link_and_img_paths(old_dom, path_to_article)
      
      journal_name = "Queue"
      html = old_dom.inner_html
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