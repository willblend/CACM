class ArticlesController < CacmController
  trackable_resource :article
  caches_action :syndicate
  skip_before_filter :authenticate_by_ip, :only => :syndicate

  radiant_layout do |c|
    c.request.format.rss? ? 'rss' : 'standard_fragment_cached'
  end
  
  # This is where things get a little unorthodox, but stay with me here:
  # Instead of the usual index + show action pair, we're adding each
  # representation of an article (abstract, fulltext, comments, PDF) as a
  # sub-resource of the primary URL. Each of these gets its own show-like action.
  #
  # Faux mime-types are not used because the access control varies too much
  # between actions and I didn't want to cram that much logic into respond_to 
  # blocks.
  #
  # Because we need to examine the current_user's authentication status as well
  # as what representations an article actually possesses (has fulltext? comments 
  # enabled?) we need some sort of URL handler to shuttle users to the
  # proper representation. And because Rails treats the index action as the
  # default route when we don't append a specific action, co-opting it to 
  # serve as the URL handler seemed like the lightweight implementation.
  def index
    if @article.full_text? and (CACM::CRAWLER_IPS.include?(request.remote_ip) or current_member.can_access?(@article, :html))
      redirect_to :action => 'fulltext'
    else
      redirect_to :action => 'abstract'
    end
  end

  # RSS Feed
  def syndicate
    article_feed_type = FeedType.find_by_name("Article")
    @articles = @vertical.articles.find(:all, :limit => 30, :include => :feed, :conditions => ["feed_type_id = ?",article_feed_type])
  end

  def fulltext
    # if there's no local fulltext, presumably this is an older article and this
    # action should not be exposed. we should never be linked to /fulltext if
    # this is the case -- but if we are, redirect to /abstract.
    redirect_to :action => 'abstract' and return if @article.full_text.blank?
    # authorization, including session staleness check
    return false unless format_accessible?(:html)

    # generate an ETag for the article's fulltext view based on when it was last updated and article.to_param
    # also include the current user and the date up to the hour so it expires in at most an hour (in case some non-article
    # content like widgets are changed on the page). And also include any flash messages so the user doesn't see them twice.
    flashmsg = flash.nil? ? "" : flash.inspect rescue "" # just in case flash isn't defined
    etag = Digest::MD5.hexdigest("#{@article.updated_at}#{@article.to_param}#{current_member.indv_client}#{Time.now.year}#{Time.now.month}#{Time.now.day}#{Time.now.hour}#{flashmsg}")
    response.headers['ETag'] = etag

    # track hits (now decoupled from session authentication)
    track_hit(:html)
  end

  # These fulltext formats get redirected via 302. They will attempt to open
  # in a popup to trigger a download (pdf, ps, txt) or display in a new
  # window, such as the digital edition and external links.
  # Like PDF, the user follows redirect to portal so we don't send a tracking hit.
  
  [:ps, :external, :digital_edition, :txt, :htm].each do |format|
    define_method format do
      raise ActionController::RoutingError.new("Article (#{@article.id}) does not have a #{format.to_s.upcase} view.") unless @article.send "has_#{format}?"
      # format_accessible? takes care of setting up the barrier page for render
      if format_accessible?(format)
        fulltext = @article.source.full_texts.send(format)
        redirect_to fulltext.url(current_member), :status => 302
      else
        return false
      end
    end
  end
  
  # because user follows redirect to portal, we don't need an artificial tracking hit.
  def pdf
    raise ActionController::RoutingError.new("Article (#{@article.id}) does not have a PDF view.") unless @article.has_pdf?
    if format_accessible?(:pdf)
      @pdf = CACM::CRAWLER_IPS.include?(request.remote_ip) ? (request.url + @article.source.full_texts.pdf.crawl_url) : (@article.source.full_texts.pdf.url(current_member))
      
      # Did we just log in? If so, we should still have the flash[:notice]..., "You have been logged in as ..."
      # Also, if the `dl` param has been set, that means we just came from the TOC
      # so we'll display the download window. Greatly speeds up TOC rendering.
      unless (flash[:notice] and flash[:notice].include?("logged")) or params[:dl]
        # No message? We are logged in. Gimme the PDF!
        redirect_to @pdf, :status => 302 and return
      end
      # else, we just logged in! Let's go to the download page to avoid a
      # nasty redirect loop. Now we render pdf.html.haml
    else 
      # never was able to access it anyways.
      return false
    end
  end
  
  # These fulltexts are displayed inline on /articles/views... either WMV,
  # MP3, or quicktime view. Since they are displayed directly on the article
  # view, they cannot be linked to in a popup with the intention of letting
  # the user authenticate themselves... and until we find a way to do that 
  # the links will only be visible to already-authenticated users.
  [:mp3,:mov,:wmv,:mp4].each do |format|
    define_method format do
      raise ActionController::RoutingError.new("Article #{@article.id}) does not have a #{format.to_s.upcase} view.") unless @article.send "has_#{format}?"
      @fulltext = @article.source.full_texts.send format
      
      if format_accessible?(format)
        render :action => "quicktime" if [:mov,:mp4].include?(format)
        track_hit(format)
      else
        return false
      end
    end
  end
  
  def abstract
    # no auth logic on abstracts
    # only DL Articles have abstracts, so throw a 404 if anything else is requested.
    raise ActiveRecord::RecordNotFound if !@article.is_dl_article?
  end

  def comments
    # this action should not be exposed if comments are disabled. why we were
    # linked to this action in the first place is another matter.
    redirect_to :action => 'abstract' and return unless @article.user_comments?
    @comments = @article.comments.paginate(:page => params[:page], :conditions => {:state => 'approved'}, :per_page => 10)
  end

  def supplements
    # NOTE : We do not want array access notation through the URL's hence 
    # why we are adding 1. If it is not found so be it, we are catching that
    # on line 12 and 19
    supplement_id = params[:id].to_i - 1
    
    if supplement_id < 0

      # we have an inclusion if the id is -1 (since inclusions get 0)
      @has_inclusion = true
      @supplement = @article.source.inclusions.first rescue nil

    else

      # Base Checking, see if the id falls within normalcy, a range of 1 to
      # the length of attached supplements.
      if (0..(@article.source.supplements.length)).member?(supplement_id)
        @supplement = @article.source.supplements[supplement_id]
      else
        raise ActiveRecord::RecordNotFound
      end
    
    end

    # If all else fails , protect against nil objects. 
    raise ActiveRecord::RecordNotFound if @supplement.nil?
    
    # Leave a return to for non-logged-in users that will see the barrier form
    session[:return] = request.request_uri unless current_member.can_access?(@article)
    
  end

  protected
    def validate_slug
      # All articles must be scoped by a vertical (Issue, Subject, Section) raise unless valid
      raise ActiveRecord::RecordNotFound unless @vertical
      
      # Find an article scoped by the article, find will raise AR::RecordNotFound if none is found
      @article = @vertical.articles.find(params[:article])
      
      # Validate the slug
      if @article.to_param == params[:article]
        true
      else
        # Capture a contextual path
        location = contextual_article_path(@article,request.path)
        # But if the location has no home ("/") raise a 404, because they shouldn't even have gotten here
        raise ActiveRecord::RecordNotFound if location.eql?("/")
        # Otherwise redirect to the proper location
        redirect_to location, :status => 301 and return false
      end
    end
    
  private
    def default_template_name(action_name = self.action_name)
    # makes subclassed controllers (subjects, sections, archives) share article templates
      if action_name
        action_name = action_name.to_s
        if action_name.include?('/') && template_path_includes_controller?(action_name)
          action_name = strip_out_controller(action_name)
        end
      end
      "articles/#{action_name}"
    end
    
    # combine per-format authentication and session expiry. sets vars needed
    # by barrier template to show the right messaging.
    def format_accessible?(format = :html)
      session[:return] = request.request_uri

      return true if CACM::CRAWLER_IPS.include?(request.remote_ip)
      if CACM::CRAWLER_AGENTS =~ request.user_agent
        render :action => 'barrier.html.haml', :content_type => 'text/html'
        return false
      end
      return true unless @article.is_a?(DLArticle) # don't authorize for 3rd party content
      unless session_valid? and current_member.can_access?(@article, format)
        @session_expired = true unless session_valid?
        render :action => 'barrier.html.haml', :content_type => 'text/html'
        false
      else
        true
      end
    end

    # Checks to see if the member's session has expired in the DL due to
    # inactivity. If so, we attempt to extend the session first by refreshing
    # member-based sessions, then by re-authenticating the user's IP.
    def session_valid?
      # can't use @session_valid ||= here because the method body will be
      # re-executed when the value is legitimately false. And we're trying to
      # be gentle with Oracle.
      unless instance_variables.include?('@session_valid')
        @session_valid = if current_member.fresh?
          true
        elsif current_member.indv?
          current_member.refresh!
        elsif current_member.inst?
          current_member.authenticate_ip
        end
      end
      @session_valid
    end
    
    def track_hit(format = :html)
      @article.track(:request => request, :format => format) unless CACM::CRAWLER_IPS.include?(request.remote_ip)
    end
end
