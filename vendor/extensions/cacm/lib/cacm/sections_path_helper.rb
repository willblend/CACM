module CACM
  module SectionsPathHelper
    
    # contextual_article_path is used to generate a URL to the article from anywhere on the site.
    # it looks at both the article's sections / subjects / magazine as well as the current URL and,
    # if it's possible, draws the link to that article within the current section/subject/path. otherwise,
    # it draws a valid path for the article (if one exists); if no valid path to the article exists,
    # it returns "/"
    def contextual_article_path(article, slug = "")
      path = slug.split("/")
      url = case
      when subject = slug.match(/^\/?(browse-by-subject\/[^\/]+)/)
        match = false
        subject_slug = path[-1]
        # make sure the article belongs to the subject in question
        # ...first, make sure the article has subjects
        if article.subjects.any?
          # can't do a article.subjects.find_by_name based on the slug because some characters
          # in the article's name may be stripped away in the slug-- i.e. 'Communications / Networking'
          # so iterate over all the article's subjects and make sure one matches the passed in subject
          article.subjects.each do |s|
            if s.to_param == subject_slug
              match = true
            end
          end
          if match
            # if we've found a match, draw the path with the specified subject
            "/browse-by-subject/#{subject_slug}/#{article.to_param}"
          else
            # otherwise, at least draw a valid link for the article so you're not taken to a 404
            "/browse-by-subject/#{article.subjects.first.to_param}/#{article.to_param}"
          end
        else
          # if the article doesn't have any subjects, what are we doing here?
          # draw whatever valid path you can for the article.
          default_article_path(article)
        end
      when slug.match(/^\/?magazines/) && article.is_a?(CacmArticle) && article.issue && article.issue.source
        # magazine paths are easy.
        url_for :controller => '/magazines', :year => article.issue.source.pub_date.year, :month => article.issue.source.pub_date.month, :article => article, :action => 'index'
      when section = slug.match(/^\/?(opinion(\/articles|\/interviews)?|news|careers|blogs)/)
        # find the most appropriate section for the article
        articlepath = nil
        if (section[0] == '/opinion')
          # Use precedence if you're on the /opinion landing page
          article.sections.each do |s|
            if (s.name == "Opinion") || (s.parent && s.parent.name == "Opinion")
              articlepath = "/#{s.to_param}/#{article.to_param}"
              break
            end
          end
          if articlepath.nil?
            # if we haven't found a section under /opinion that matches this article, just return the first section for the article
            articlepath = default_article_path(article)
          end
          articlepath
        elsif (section[0] == '/blogs')
          # the only blog articles that are linked to on-site are Blog CACM (née Communications Blog) articles
          if section = article.sections.find_by_name("Blog CACM")
            articlepath = "/#{section.to_param}/#{article.to_param}"
          end
          if articlepath.nil?
            # if we haven't found a section under /opinion that matches this article, just return the first section for the article
            articlepath = default_article_path(article)
          end
          articlepath
        else
          # otherwise just use the full slug
          match = false

          # /opinion/articles only shows articles with section = "opinion"
          slug_section = section[0][1..-1]
          article.sections.each do |s|
            if s.to_param == slug_section
              match = true
            end
          end
          
          if match
            # if we've found a section on this article that matches the slug, draw it
            "#{section[0]}/#{article.to_param}"
          else
            # otherwise, we shouldn't be here, but at least draw a valid link
            default_article_path(article)
          end
        end
      else # can't figure out where we are from the slug or no slug was passed in - look at the article itself
        default_article_path(article)
      end
    end

    # default_article_path is called by contextual_article_path when a valid path matching the current page's URL can't
    # be found for the article or if no URL slug was passed in.  returns the first valid path for the article (if one exists).
    # order of precedence: magazine path, section path, subject path, "/".
    def default_article_path(article)
      if article.is_a?(CacmArticle) && article.issue && article.issue.source
        url_for :controller => '/magazines', :year => article.issue.source.pub_date.year, :month => article.issue.source.pub_date.month, :article => article, :action => 'index'
      elsif article.sections.any?
        section = article.sections.find(:first)
        if section.name == "Syndicated Blogs"
          # This is an external blog link; the only valid link for the article is to its source.
          # note that it's up to the caller of this function to know that this is an external
          # link and to draw the appropriate external link icon.
          # Since the section model is ordered and syndicated blogs is the last in that ordering,
          # find(:first) will only return syndicated blogs if the article's only section is
          # syndicated blogs.
          article.link
        else
          "/#{section.to_param}/#{article.to_param}"
        end
      elsif article.subjects.any?
        "/browse-by-subject/#{article.subjects.first.to_param}/#{article.to_param}"
      else # how'd we get here?
        "/"
      end
    end

  end
end