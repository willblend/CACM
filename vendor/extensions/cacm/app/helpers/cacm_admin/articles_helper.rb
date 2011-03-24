module CacmAdmin::ArticlesHelper

  # an LI with 'Selected' class if link URL is current page, plus link_or_span_for_current
  def navigation_list_item_feed(name, options = {}, html_options = {}, &block)
    content_tag :li, link_to(name, options, html_options, &block), :class => (current_page_without_params?(options) ? 'Selected' : '')
  end

  # this exists so we can compare URLs ignoring certain query parameters. 
  # useful for controlling the active state of tabs when one action may handle 
  # multiple tab states, all via query params.
  def current_page_without_params?(options)
    url_string = CGI.escapeHTML(url_for(options))
    request = @controller.request
    
    if url_string =~ /^\w+:\/\//
      url_string == "#{request.protocol}#{request.host_with_port}#{request.request_uri}"
    else
      p = request.parameters.except(:page, :sort, :direction, :commit, :feed_id, :index)
      if params[:filter] == 'new'
        url_string == url_for(p.except(:filter))
      elsif params[:filter].blank?
        p[:filter] = "all"
        url_string == url_for(p)
      else
        url_string == url_for(p)
      end
    end
  end
  
  
  def build_navigation_bar(params)
    
    returning [] do |s|
      filters = [["Inbox" , "new"],["Approved", "approved"],["Rejected" , "rejected"],["all" , ""]].each do |filter|      
          # Are we coming from a TS Search?  then no tab highlight, otherwise some conditions apply
          if params[:query]
            klass = nil
          else
            if params[:filter]            
              if params[:filter].empty? 
                # Filter is an empty parameter if inbox is selected, so if we have an emtpy filter make the inbox selected 
                klass = filter[0] == "Inbox" ? "Selected" : nil
              else
                # Otherwise match teh filter to a memeber of the array to determine which tab should be selected
                klass = params[:filter] == filter[0] ? "Selected" : nil
              end
            else
              # This is the sitaution where we have just arrived on this page,  no filters at all, set inbox to be selected
              klass = "Selected" if filter[0] == "Inbox" 
            end
          end
                 
          # Grab count of articles 
          count_conditions = filter[0] == "all"  ? "state != 'archived'" : "state = '#{filter[1]}'"  
          # It we are coming from the blog route add conditions 
          if request.request_uri.match(/admin\/blog/)  
            count_conditions += (count_conditions.empty? ? "feed_id = '#{params[:feed_id]}'" : "AND feed_id = '#{params[:feed_id]}'" )
          end
          article_count = Article.count(:all, :conditions => count_conditions)
          
          # Never persist the query, it is never meant to be passed to the tabs but duplicate the parameters
          # hash to protect against side effects
          parameters = params.dup
          parameters.delete(:query) if params[:query]

          
          # Now build the LI's
          s << content_tag(:li,:class => klass) do
		content_tag(:a, :href => url_for(parameters.merge({:action => "index", :filter => (filter[0] == "Inbox") ? "" : filter[0]}))) do
                  filter[0].capitalize + content_tag(:small) do
                    " (" + article_count.to_s + ")"
                  end
                end
               end  
      end
    end
  end
  
  
  # This is another issue related to the blogger role and having everything crammed in one route
  # if we are coming from the blogger route then only the blog cacm section should be checkable.
  def disable_section_buttons(section,request_uri)
    (section.name != "Blog CACM" && request_uri.match(/admin\/blog/) ) ? true : false
  end

end
