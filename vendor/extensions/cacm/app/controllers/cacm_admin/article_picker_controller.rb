class CacmAdmin::ArticlePickerController < ApplicationController
  only_allow_access_to :associated_articles, :prepare_articles_for_picking,
    :when => CACM::FULL_ACCESS_ROLES,
    :denied_url => {:controller => 'admin/page', :action => 'index'},
    :denied_message => 'You are not authorized to view that page.'
  
  
  include ActionView::Helpers::JavaScriptHelper
  helper 'cacm_admin/articles'
  layout "application_popup.html.erb"
  
  def associated_articles
    respond_to do |format|
      
      format.html do
        prepare_articles_for_picking
        render :action => :index
      end
      
      format.js do
        if params[:data]
          article_nodes = []
          params[:data].split(",").each do |node|
            article = Article.find(node) rescue nil
            unless article
              article_nodes = nil
            else
              article_nodes << { :id => article.id, :title => scrub_titles(escape_javascript(article.title)) }
            end
          end
          render :text => array_or_string_for_javascript(article_nodes.to_json).squeeze("\\")
        else
          prepare_articles_for_picking
          render :action => :index
        end
      end
      
    end
  end
  
  def prepare_articles_for_picking
    
    # KAS 02/11/09
    #
    # Trying to straighten this up a little bit so we have a better pattern 
    # going forward for item picking mixed in with search and robust filtering
    
    # Take in sort column and direction parameters or default to `date desc`
    sort = params[:sort] ? params[:sort] : "articles.date"
    dir = params[:direction] ? params[:direction] : "desc"
    order_conditions = [sort, dir].join(" ")
    
    # Search
    # 
    # Articles  => Search Results
    # Feeds     => All Feeds (including books, events, courses)
    # Total     => Count of All Approved Articles In System
    # Title     => Search Query
    if params[:query]
      # Split order conditions past the the period, because articles.something will return no results
      order_conditions = order_conditions.split(".").last

      # David's Tokenization
      query = params[:query].blank? ? '' : "#{params[:query]}*"
      
      # Build conditions checking for the presence of a scoped search
      if params[:feed_id]||params[:feed_ids]
        feeds = (params[:feed_id]||params[:feed_ids]).split(',')
        @feeds = Feed.find_all_by_id(feeds)
        @title = "<strong>Your Search:</strong> #{params[:query]} <br /><strong>Within Feeds:</strong> #{@feeds.map(&:name).join(', ')}"
        conditions = {:state => "approved", :feed_id => @feeds.map(&:id)}
      else
        @feeds = Feed.find(:all)
        @title = "<strong>Your Search:</strong> #{params[:query]}"
        conditions = {:state => "approved"}
      end
      
      @articles = Article.search(query, :page => params[:page], :per_page => 25, :conditions => conditions, :order => order_conditions)
      @total_articles = @articles.total_entries

    # Section Specific Articles
    #
    # Articles  => All approved Articles associated with specified Section
    # Feeds     => Pickable Feeds (article / blog feeds)
    # Total     => Total Approved Articles in Section
    # Title     => Section Name
    elsif params[:section_id]  
      @articles = Article.find(:all, :conditions => ["state = 'approved' AND sections.id = ?", params[:section_id]], :include => :sections, :order => order_conditions)
      @feeds = Feed.picking_feeds
      @total_articles = @articles.size
      @title = "<strong>Displaying approved articles from section:</strong> #{Section.find(params[:section_id]).name}"

    # Issue Specific Articles
    #
    # Articles  => All approved Articles associated with an issue
    # Feeds     => CACM Feed arrayified
    # Total     => Total Approved Articles in Issue
    # Title     => Issue Title
    elsif params[:issue]
      @articles = Article.find(:all, :conditions => ["state = 'approved' AND issue_id = ?", params[:issue]], :order => order_conditions)
      @feeds = CacmFeed.find(:all)
      @total_articles = @articles.size
      @title = "<strong>Displaying approved articles from:</strong> #{Issue.find(params[:issue]).source.title}"

    # Everything Else Gets Pagination
    else
      # Set up some pagination
      pag = { :page   => params[:page],
              :filter => "approved",
              :order  => order_conditions,
              :search => params[:search],
              :index  => params[:index],
              :include => :feed }

      # Feed(s) Specific Articles
      #
      # Articles  => Approved, Paginated, associated with specified feed
      # Feeds     => User Specified Feeds
      # Total     => Total Approved Articles associated with specified feed
      # Title     => Concatenated Feed Names
      if params[:feed_id] || params[:feed_ids]
        # Take feeds from either param source split them into an array
        feeds = (params[:feed_id]||params[:feed_ids]).split(',')
        @feeds = Feed.find_all_by_id(feeds)
        @title = "<strong>Displaying approved articles from feed(s):</strong> #{@feeds.map(&:name).join(', ')}"

      # Default Conditions
      #
      # Articles  => Approved, Paginated, associated with pickable feeds
      # Feeds     => All Pickable Feeds
      # Total     => Total Approved Articles associated with pickable feeds
      # Title     => Default
      else
        @feeds = Feed.picking_feeds
        @title = "Displaying all approved articles"
      end

      # Set up pagination condition and...
      pag[:conditions] = ["feed_id IN (?)", @feeds.map(&:id)]

      # PAGINATE!
      @articles = Article.paginate( pag )
      
      # Now get the total count for the same conditions
      @total_articles = Article.count(:all, :conditions => ['feed_id IN (?) AND state = (?)',@feeds.map(&:id),"approved"])
    end
  end
  
  # Give our article titles a JSON-foolproof scrubbing, as escape_javascript
  # doesn't take care of everything we might find in an article title. - amlw 4/17
  def scrub_titles(text)
    
    # We don't want brackets in our JSON array, so we'll change them to parens
    text.gsub!("[","(")
    text.gsub!("]",")")
    
    # And let's get rid of unicode characters, too...
    text = text.chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').to_s
    
    # And just avoid double quotes for displaying titles.
    text.gsub!("\"","\'")
    
    return text
  end
  
end