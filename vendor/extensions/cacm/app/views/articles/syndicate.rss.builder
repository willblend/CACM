xml.rss :version => "2.0" do
  xml.channel do
    @rssfeed = rss_feed_info(@vertical)
    xml.title @rssfeed[:title]
    xml.description @rssfeed[:description]
    xml.link @rssfeed[:link]   

    for article in @articles
      xml.item do
        xml.title strip_tags(article.title)
        xml.description truncate_html(article.short_description, 750, "&hellip;")
        xml.pubDate article.date.to_s(:rfc822)
        xml.link @rssfeed[:site_url] + contextual_article_path(article, @rssfeed[:path])
        xml.guid @rssfeed[:site_url] + contextual_article_path(article, @rssfeed[:path])
        article.subjects.each do |s|
          xml.category s.name
        end
      end
    end
  end
end