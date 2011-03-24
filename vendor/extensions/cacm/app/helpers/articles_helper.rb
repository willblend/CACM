module ArticlesHelper
  
  def active_li_if(cond, opts={})
    if opts.has_key? :class and cond
      opts[:class] = opts[:class] + " active"
    elsif !opts.has_key? :class and cond
      opts.merge!(:class => 'active') if cond
    end
    content_tag :li, nil, opts do
      yield if block_given?
    end
  end

  def rss_feed_info(vertical)
    title = ""
    description = ""
    link = ""
    path = ""
    site_url = request.port == 3000 ? "http://#{request.host}:3000" : "http://#{request.host}"
    
    case vertical.class.name
    when "Subject"
      name = Subject.find(vertical.id).name
      title = "Communications of the ACM: #{name.titleize}"
      description = "The latest news, opinion and research in #{name}, from Communications online."
      link = url_for(:controller => "subjects", :action => "syndicate", :subject => vertical.id, :only_path => false)
      
    when "Issue"
      title = "Communications of the ACM: Latest Issue"
      description = "Articles from the latest issue of Communications of the ACM."
      path = ""
      link = url_for(:controller => "magazines", :action => "syndicate", :only_path => false)
      
    when "Section"
      link = url_for(:controller => "sections", :action => "syndicate", :section => vertical.id, :only_path => false)
      path = "/#{vertical.to_param}/"
      case vertical.name
      when "Blog CACM"
        title = "Communications of the ACM: blog@CACM"
        description = "Communications online bloggers share their expertise."
      when "Careers"
        title = "Communications of the ACM: Careers"
        description = "Information on career trends and opportunities from Communications online."
      when "News"
        title = "Communications of the ACM:  News"
        description = "Advanced computing news from Communications online."
      when "Opinion"
        title = "Communications of the ACM:  Opinion"
        description = "Opinion articles and interviews from Communications online."
      end
    end

    { :title => title, :description => description, :path => path, :link => link, :site_url => site_url }
  end
  
  # NOTE 
  # This is a copy of a method is aavailable on the comment class, it is here to allow for the proper 
  # information to be displayed to a user in the event that they do not have a first or last name 
  def current_member_commenting(current_user)
    if !current_member.inst? && !current_member.indv?
      "Anonymous"
    elsif current_user.name_last.blank? && current_user.name_first.blank?
      current_user.username
    else
      [current_user.name_first,current_user.name_last].compact.join(' ')
    end
  end
  
  def publication_source_name(article)
    if @article.is_dl_article?
      if @article.is_a?(CacmArticle)
        if @article.source.section
          @article.source.section.title
        else
          "Communications of the ACM"
        end
      else
        if @article.class.name == "DLArticle"
          "Communications of the ACM"
        else
          @article.source_human_name
        end
      end
    else
      h(@article.feed.name) 
    end
  end
  
  def correct_crawl_url(crawl_url)
    return "http://" + "delivery.acm.org:8080/#{crawl_url}".squeeze("/")
  end

end
