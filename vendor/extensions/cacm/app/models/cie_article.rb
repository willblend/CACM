class CIEArticle < DLArticle
  
  def source_human_name
    "From Computers in Entertainment"
  end
  
  def self.retrieve(doi)
    local = super(doi) do |article|

      article.feed_id = CACM::DL_FEED_ID
      if fulltext = article.fetch_dl_data
        # fulltext => [response.body, path]
        html = article.extract_content(fulltext[0], fulltext[1])
        article.full_text = html[:full_text]
        article.leadin = html[:leadin]
        article.toc = html[:toc]
        article.short_description = article.leadin if article.short_description.blank?
      end
    end
    yield local if block_given?
    return local
  end

  def extract_content(html, path_to_article)
    CIEArticle.parse_html(Hpricot(html), path_to_article)
  end

  class << self
    def parse_html(old_dom, path_to_article)

    end
  end
end