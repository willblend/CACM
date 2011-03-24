module CacmHelper
  
  def month_from_number(numb)
    case numb.to_i
      when 1 : "January"
      when 2 : "February"
      when 3 : "March"
      when 4 : "April"
      when 5 : "May"
      when 6 : "June"
      when 7 : "July"
      when 8 : "August"
      when 9 : "September"
      when 10 : "October"
      when 11 : "November"
      when 12 : "December"
      else
      ""
    end
  end
  
  # Sometimes the date helpers just aren't all that helpful! This one will
  # return 12 option tags as a string, with the current_month selected.
  # If you want a blank field on your select, or a title, DIY!
  # This is a "stupid helper" because sometimes stupid is better.
  
  def month_options_for_select(current_month)
    current_month = 0 if current_month.nil?
    returning [] do |output|
      1.upto(12) do |month_number|
        selected = current_month.to_i.eql?(month_number) ? " selected=\"selected\"" : ""
        output << "<option value=\"#{month_number}\"#{selected}>#{Date::MONTHNAMES[month_number]}</option>"
      end
    end.join("\n")
  end
  
  def display_flashes
    html = []

    [:notice, :error, :warning].each do |f|
     unless flash[f].blank?
       html << content_tag(:div, flash[f], :id => "Flash" + f.to_s.capitalize, :class => "Flash")
     end
    end

    html.join("\n")
  end
  
  class WidgetHelper
    include Singleton
    include ActionView::Helpers::SanitizeHelper
  end
  
  def sanitizer
    WidgetHelper.instance
  end
  
  def post_process_gsa_results(html)
    # adjust the search results to match the host
    html = html.gsub("beta.cacm.acm.org", request.host_with_port)

    # even in XML mode, the descriptions for the search results still use HTML4-style BR tags. ugh.
    html.gsub("<br>", "<br />")
  end
  
  def add_tokens_to_portal_urls(snippet, cf_id, cf_token)
    snippet.gsub(DP::REGEXP::URL) do |a|
      url = URI.parse(a)
      if url.host =~ /portal(test)?\.acm\.org/
        url.query ||= ''
        url.query += "&CFID=#{cf_id}&CFTOKEN=#{cf_token}"
      end
      url.to_s
    end
  end
  
  def add_tokens(&block)
    html = block.call
    add_tokens_to_portal_urls(html, current_member.session_id, current_member.session_token)
  end
  
  # We never want google indexing PDFs if there is a full-text, but if the
  # current user is authorized to view the PDF, they will be redirected to
  # the PDF itself, so we need to add a target="_blank" to the link to
  # avoid the re-direct loop.
  
  def article_pdf_link_options(article)
    returning Hash.new do |opts|
      # check for regular and anon. access before caching this link
      opts[:target] = '_blank' if current_member and current_member.can_access?(article, :pdf)
      opts[:rel] = 'nofollow' if article.full_text?
    end
  end
  
  # When previewing an article, we need to generate working links to the
  # various article actions, but we don't know what controller it would be
  # accessed with. This helper will check to see if it can generate a valid
  # path on sections, subjects, and magazines. If no routes can be drawn,
  # or something totally unexpected occurs, the code will break and be rescued 
  # by just returning nil, which will be disregarded for "#" on the view.
  # used on "articles/preview.html.haml" - amlw 3/3
  
  def contextual_article_preview_path(article, action)
    
    begin
      returning Hash.new do |path|
        path[:article] = article.id || 1
        path[:action] = action
        
        if article.sections.any?
          path[:controller] = "/sections"
          path[:section] = article.sections.first.id
        elsif article.subjects.any?
          path[:controller] = "/subjects"
          path[:subject] = article.subjects.first.id
        elsif article.is_a? CacmArticle
          path[:controller] = "/magazines"
          path[:year] = article.date.year
          path[:month] = article.date.month
        end
      end
      
    rescue
      nil
    end
    
  end

  def preview?
    if request.parameters["controller"].eql?("preview") || request.parameters["action"].eql?("preview")
      true
    else
      false
    end
  end
  
  # This method finds a subject by reversing the to_param method and finding the match.
  def subject_from_url
    if preview?
      Subject.find(:all).select { |s| s.to_param == request.parameters["page"]["slug"] }.first rescue nil
    else
      return nil unless request.parameters["url"].is_a? Array
      Subject.find(:all).select { |s| s.to_param == request.parameters["url"].last }.first rescue nil
    end
  end

  def article_from_url
    if preview?
      nil
    else
      Article.find_by_id(request.parameters["article"])
    end
  end
  
end