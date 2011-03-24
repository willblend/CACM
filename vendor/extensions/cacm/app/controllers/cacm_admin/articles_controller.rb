class CacmAdmin::ArticlesController < ApplicationController

  include CACM::DLSession

  listable_resource :article,
                    :sorts => ['title', 'date'],
                    :default => 'date',
                    :only => :index

  helper_method :index_options

  before_filter :include_date_javascript
  
  cache_sweeper :article_sweeper
    
  def index
    if params[:query]

      # Set up hash
      conditions = {}
      
      # Tokenize and remove user inputted stars, JSGMF style
      terms = params[:query].blank? ? '' :  params[:query].gsub(/\*/, "").split.join("* ") << "*"

      # Special sort to use lower cased title
      params[:sort] = "title_sort" if !params[:sort].blank? && params[:sort].eql?("title")

      # Build up conditions hash
      (conditions[:with] = {:feed_id => params[:feed_id] }) unless params[:feed_id].blank?
      (conditions[:order] = params[:sort].intern) unless params[:sort].blank?
      (conditions[:sort_mode] = params[:direction].intern) unless params[:direction].blank?
      conditions[:conditions] = {:state => '!= archived'}
      conditions[:page] = params[:page]
      conditions[:per_page] = 30
      
      @articles = Article.search(terms, conditions)
      
      # Keep this around for the counts later on
      @stateless_filter_conditions = ""
      # When a feed_id is present keep it from being lost to keep the aritlces totals for the tabs correct. 
      @stateless_filter_conditions << "feed_id = #{params[:feed_id]}" if params[:feed_id] && !params[:feed_id].blank?
    
    else
      # Preparing the :conditions for the upcoming Article.find statement
      filter_conditions = []
      
      # Filter by date!
      if params[:year_filter] && !params[:year_filter].blank?
        if !params[:month_filter].blank?
          start_date = Date.civil(params[:year_filter].to_i, params[:month_filter].to_i, 1)
          end_date = Date.civil(params[:year_filter].to_i, params[:month_filter].to_i, -1)
        else # NOTE: There is no filtering just by month. Disabled via JS.
          start_date = Date.civil(params[:year_filter].to_i, 1, 1)
          end_date = Date.civil(params[:year_filter].to_i, 12, 31)
        end
        filter_conditions << "date >= '#{start_date}' AND date <= '#{end_date}'"
      end
      
      # Filter by feed!
      filter_conditions << "feed_id = #{params[:feed_id]}" if params[:feed_id] && !params[:feed_id].blank?
      
      # Save these for when we put together the tabs...
      # NOTE: At the moment I'm not adding up all the feeds counts because
      # the querying got a bit too intense. Try to find a way to do those
      # in a sane manner. - amlw 12/22
      @stateless_filter_conditions = filter_conditions.join(" AND ")
      
      # Filter by article status!
      # NOTE: This has to come before we grab the @filtered_articles
      if params[:filter] && !params[:filter].blank?
        # /articles (no visible filter params in URL) is actually the 'new' filter.
        # /articles?filter=all is actually no filter applied
        status_clause = params[:filter].eql?("all") ? "" : "state = '#{params[:filter]}'"
      else
        status_clause = "state = 'new'"
      end
      filter_conditions << status_clause unless status_clause.blank?
      
      # Add sort param! (This used to be done via will_paginate, but that only
      # happens when it's hijacking the find method. Since we're passing it
      # an array, we need to do sorting manually before we paginate)
      # NOTE: Make sure that we're not setting ourselves up for situations
      # where it takes two sorts to update the sort. Might need some tinkering
      # in the method that builds the sort links. -amlw 12/22
      if params[:direction].nil? && params[:sort].nil?
        order_conditions = "articles.date desc"
      elsif params[:direction].nil? && !params[:sort].nil?
        order_conditions = "articles." + params[:sort] + " asc"
      else
        order_conditions = "articles." + params[:sort] + " " + params[:direction]
      end
      
      # Now prepare the pagination of the filtered articles we just found...
      pag = { :page   => params[:page],
              # default view is reverse chronological
              :search => params[:search],
              :select => 'id, title, date, approved_at, updated_at, status, feed_id, class_name',
              :index  => params[:index],
              :include => :feed, 
              :conditions => filter_conditions.join(" AND "), 
              :order => order_conditions }
      
      # And paginate!
      @articles = Article.paginate(pag)

    end
    
    # Calculate total for tabs, e.g. Rejected (42)
    @total_inbox    = @articles.nil? ? Article.total_inbox : Article.count(:all, :conditions => (@stateless_filter_conditions).empty? ? "state = 'new'" : @stateless_filter_conditions + " and state = 'new'")
    @total_approved = @articles.nil? ? Article.total_approved : Article.count(:all, :conditions => (@stateless_filter_conditions).empty? ? "state = 'approved'" : @stateless_filter_conditions + " and state = 'approved'")
    @total_rejected = @articles.nil? ? Article.total_rejected : Article.count(:all, :conditions => (@stateless_filter_conditions).empty? ? "state = 'rejected'" : @stateless_filter_conditions + " and state = 'rejected'")
    # 'archived' article = dead to us.
    @total_articles = @articles.nil? ? Article.count : Article.count(:all, :conditions => (@stateless_filter_conditions).empty? ? "state != 'archived'" : @stateless_filter_conditions + " and state != 'archived'")
    @manual_feeds = ManualFeed.all_feeds
    
    # This used to list out the number of articles in each feed. I've changed
    # it to just map out the names for the moment, because it SHOULD be 
    # accurate and take the current feeds into account. This means that we
    # have some bulky queries. Find a smarter way to do this, or just grit
    # your teeth and assume beta is faster than local.
    # And, in a perfect world, we SHOULD also pass in some values for the 
    # "total" amount of articles in each feed (and each tab, listed above)
    # so that when a user clicks "reset" on the filter form, the numbers
    # snap back to the true results of clicking Filter using JS. - amlw 12/22
    @feed_options = Feed.find(:all, :select => 'id,name', :order => :name).map { |f| [f.name + " (#{Article.count(:all, :conditions => ["feed_id = (?)#{' and ' + status_clause unless status_clause.blank?}", f.id])})", f.id] }
    
    # Grab the earliest and latest articles for year filtering selects
    lower = Article.minimum(:date).year rescue 1958
    upper = Article.maximum(:date).year rescue Date.today.year
    @year_range = (lower..upper).to_a
  end
  
  def edit
    current_member.authenticate_user(:user => CACM::ADMIN_USER, :passwd => CACM::ADMIN_PASS) unless current_member.indv?
    @article = Article.find(params[:id])

    @subjects = Subject.find(:all)
    # if the article is a DLArticle, don't allow it to be featured in the syndicated blogs (#262)
    @sections = Section.find(:all, :conditions => ["name NOT IN (?)", ['Blogroll', 'Blogs']])
  end
  
  def show
    @article = Article.find(params[:id])
  end

  def new
    if params[:provider_id].blank?
      flash[:error] = 'Please specify a Content Provider.'
      redirect_to admin_articles_path(index_options)
    elsif Feed.find_by_id(params[:provider_id]).nil?
      flash[:error] = 'Content Provider not found.'
      redirect_to admin_articles_path(index_options)
    else
      @article = ManualArticle.new(:feed_id => params[:provider_id])
      @subjects = Subject.find(:all)
      @sections = Section.find(:all, :conditions => ["name NOT IN (?)", ['Blogroll', 'Blogs']])
      # prepopulate any sections set by the article's feed.
      @article.sections << @article.feed.sections
    end
  end

  # POST /feeds
  def create
    @article = ManualArticle.new(params[:article])
    @subjects = Subject.find(:all)
    @sections = Section.find(:all)
    @feeds = ManualFeed.find(:all, :order => 'name ASC')

    @article.uuid = "#{Time.now.to_f}:#{@article.title}"

    # dates are coming through without a timestamp, so set the time of the post to the current hour & minute
    @article.date = @article.date + Time.now.hour*3600 + Time.now.min*60

    if @article.save
      if params[:commit].downcase.include? 'approve'
        @article.approve!
        if @article.state == 'approved'
          flash[:notice] = 'Article was successfully created and approved.'
          redirect_to({:action => "index"}.merge!(index_options)) 
        else
          error = @article.errors[:sections].nil? ? "Article was saved but not approved." : "Article was saved but not approved. #{@article.errors[:sections].first}"
          flash[:error] = error
          redirect_to({:action => "edit", :id => @article.id}.merge!(index_options)) 
        end
      else
        flash[:notice] = 'Article was successfully created.'
        redirect_to({:action => "index"}.merge!(index_options)) 
      end
    else
      flash.now[:error] = 'Unable to save Article.'
      render :action => "new"
    end
  end
  
  def update
    @subjects = Subject.find(:all)
    @sections = Section.find(:all)
    @article = Article.find(params[:id])


    # dates are coming through without a timestamp, so set the time of the post to the current hour & minute
    params[:article]["date"] = params[:article]["date"] + " #{Time.now.hour}:#{Time.now.min}" unless params[:article]["date"].nil?

    @article.featured_article = params[:article]["featured_article"]

    # since the date's coming through via the rails datehelper, we're looking at the 
    # article itself to see if its approved_at date was changed rather than the params.
    approved_at = @article.approved_at # store the article's approval date...
    
    if @article.update_attributes(params[:article])
      # if we're approving or rejecting the article, do so here
      if params[:commit].downcase.include? 'approve'
        # if approved_at changed, the form option was set to manually override the approved_at timestamp
        approved_at = (@article.approved_at != approved_at) ? @article.approved_at : nil
        
        # try to approve the article
        @article.approve!
        if @article.state == 'approved'
          # so... if approved_at changed, use that for the timestamp
          if approved_at
            @article.approved_at = approved_at
            @article.save
          end
          flash[:notice] = "Article saved and approved."
          redirect_to({:action => "index"}.merge!(index_options)) 
        else # article couldn't be approved
          # calling .first on @article.errors[:sections] here because this error is generated twice on the article at this point-
          # once on @article.update_attributes and once on approve!
          error = @article.errors[:sections].nil? ? "Article was saved but not approved." : "Article was saved but not approved. #{@article.errors[:sections].first}"
          flash[:error] = error
          render :action => "edit"
        end        
      elsif params[:commit].downcase.include? 'reject'
        @article.reject!
        flash[:notice] = "Article saved and rejected."
        redirect_to({:action => "index"}.merge!(index_options)) 
      else
        flash[:notice] = "Article saved."
        redirect_to({:action => "index"}.merge!(index_options)) 
      end
    else
      # hack to show sections (HABTM) error
      if @article.errors[:sections]
        # ...but not calling .first here, because there should only be one error in errors[:sections], 
        # so calling .first on it only returns the first letter of the error.
        error = @article.errors[:sections].nil? ? "Article was saved but not approved." : "Article was saved but not approved. #{@article.errors[:sections]}"
        flash[:error] = error
      else
        flash.now[:error] = 'Please correct the errors below.'
      end
      render :action => 'edit'
    end
    MetaTag.find(:all).each do  |mt|
      mt.destroy if mt.articles.count.zero?
    end

  end

  def reject
    @article = Article.find(params[:id])
    @article.reject!
    flash[:notice] = 'Article rejected.'
    redirect_to admin_articles_path(index_options)
  end
  
  def refresh
    @article = Article.find(params[:id])
    @article.refresh
    flash[:notice] = 'Article refreshed.'
    redirect_to edit_admin_article_path(@article, index_options)
  end
  
  private

    def index_options
      params[:page] ||= 1
      params[:sort] ||= 'date'
      params[:direction] ||= 'desc'
      {:index => params[:index], :page => params[:page], :sort => params[:sort], :direction => params[:direction], :feed_id => params[:feed_id], :filter => params[:filter]} 
    end
    
    def include_date_javascript
      @javascripts << 'admin/DatePicker'
      @javascripts << 'validation'
    end
    
  
end
