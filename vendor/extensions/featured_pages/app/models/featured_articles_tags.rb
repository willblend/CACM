module FeaturedArticlesTags
  include Radiant::Taggable
  
  desc %{ 
    Returns all featured articles. Accepts a limit and/or order parameter.
  
    *Usage:*
    <pre><code><r:featured_articles [limit="1" order="published_at ASC"]>...</r:featured_articles></code></pre>
  }

  tag 'featured_articles' do |tag|
    limit = tag.attr["limit"] || nil
    order = tag.attr["order"] || nil
    find_options = {:conditions => ['featured_article = ? and virtual = ?', true, false]}
    unless order.nil?
      find_options.merge!(:order => order)
    end
    unless limit.nil? 
      find_options.merge!(:limit => limit)
    end
    tag.locals.featured_articles = Article.find(:all, find_options)
    tag.expand unless tag.locals.featured_articles.empty?
  end
  
  desc %{
    Returns an individual article from the featured_articles scope
    
    *Usage:*
    <pre><code><r:featured_articles:each>...</r:featured_articles:each></code></pre>
  }
  tag 'featured_articles:each' do |tag|
    result = []
    tag.locals.featured_articles.each do |p|
      tag.locals.article = p
      result << tag.expand
    end
    result
  end
  
  desc %{
    Returns the first article from the featured_articles scope
    
    *Usage:*
    <pre><code><r:featured_articles><r:if_first>...</r:if_first></r:featured_articles></code></pre>
  }
  tag 'featured_articles:if_first' do |tag|
    articles = tag.locals.featured_articles
    if first = articles.first
      tag.locals.article = first
      tag.expand
    end
  end
  
  desc %{
    Returns all articles that are not the first article in the featured_articles scope.
    
    *Usage:*
    <pre><code><r:featured_articles><r:unless_first>...</r:unless_first></r:featured_articles></code></pre>
  }
  tag 'featured_articles:unless_first' do |tag|
    result = []
    tag.locals.featured_articles.each do |p|
      tag.locals.article = p
      result << tag.expand unless tag.locals.featured_articles.first == p
    end
    result
  end
end
