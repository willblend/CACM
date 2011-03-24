class CacmAdmin::FeedsController < ApplicationController
  only_allow_access_to :new, :create, :edit, :update, :ingest,
    :when => CACM::FULL_ACCESS_ROLES,
    :denied_url => {:controller => 'admin/page', :action => 'index'},
    :denied_message => 'You are not authorized to view that page.'

  before_filter :get_feed_data, :except => [:ingest]

  def index
    @feeds = Feed.find(:all, :order => 'name ASC')
  end

  # GET /feeds/new
  def new
    @feed = Feed.new
  end

  # POST /feeds
  def create
    if (params[:feed][:class_name] == 'ManualFeed')
      @feed = ManualFeed.new(params[:feed])
    elsif (params[:feed][:class_name] == 'CacmFeed')
      @feed = DigitalLibraryFeed.new(params[:feed])
    else
      # default to RssFeed
      @feed = RssFeed.new(params[:feed])
    end

    if @feed.save
      # if we're creating a new blog RSS feed, add 'blogroll' to its sections
      if @feed.feed_type.name == "Blog" && @feed.class == RssFeed
        @feed.sections.clear # 'blogroll' is the *only* section for this feed
        @feed.sections << Section.find_by_name("Blogroll")
      end
      flash.now[:notice] = 'Feed was successfully created.'
      redirect_to admin_feeds_path
    else
      flash.now[:error] = 'Unable to save feed.'
      render :action => "new"
    end
  end

  def edit
  end

  def ingest
    @feed = Feed.find(params[:id])
    Article.suspended_delta do
      @feed.ingest
    end
    
    flash.now[:notice] = 'Feed ingested.'
    redirect_to admin_feeds_path
  end

  def update
    if @feed.update_attributes(params[:feed])
      if @feed.feed_type.name == "Blog" && @feed.class == RssFeed
        @feed.sections.clear # 'blogroll' is the *only* section for this feed
        @feed.sections << Section.find_by_name("Blogroll")
      end
      flash.now[:notice] = "Feed updated."
      redirect_to admin_feeds_path
    else
      flash.now[:error] = 'Please correct the errors below.'
      render :action => 'edit'
    end
  end

  private

    def get_feed_data
      @feed = Feed.find(params[:id]) unless params[:id].blank?

      @subjects = Subject.find(:all)
      @sections = Section.find(:all, :conditions => ["name NOT IN (?)", ['Blogroll', 'Blogs']])
      @feed_types = FeedType.find(:all, :order => 'name ASC')
    end
  
end
