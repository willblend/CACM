class CacmAdmin::IssuesController < ApplicationController
  
  protect_from_forgery :except => :fetch
  
  only_allow_access_to :index, :publish, :unpublish,
    :when => CACM::FULL_ACCESS_ROLES,
    :denied_url => {:controller => 'admin/page', :action => 'index'},
    :denied_message => 'You are not authorized to view that page.'
  
  def index
    unless params[:year]
      @issues = Issue.paginate(:page => params[:page])
    else
      # Get Oracle Issues, from them get the locals, remove any nils for local issues that don't exist
      @issues = Oracle::Issue.year(params[:year]).map(&:local).compact
    end
  end
  
  def update
    @issue = Issue.find(params[:id])
    @issue.attributes = params[:issue]
    
    unless request.xhr?
      if @issue.save
        flash[:notice] = "Issue updated and saved successfully!"
      else
        flash[:error] = "There was a problem updating the issue!"
      end
      redirect_to admin_issues_path
    else
      if @issue.save
        render :text => "Success"
      else
        render :text => "Failure"
      end
    end
  end

  def new
    @issue = Issue.new
  end
  
  # fetches an entire issue from the system, based on the issue's Oracle ID
  def fetch
    respond_to do |format|
      format.js {
        render :text => fetch_issue
      }
    end

  end

  def publish
    @issue = Issue.find(params[:id])

    if @issue.approve! && @issue.approved?
      flash[:notice] = "The issue #{params[:articles] ? 'and its articles': ''} has been published!"
    else
      flash[:error] = "There was a problem publishing the issue! <br /> Please select at least one article to feature before you approve this issue"
    end
    redirect_to admin_issues_path
  end

  def unpublish
    @issue = Issue.find(params[:id])
    @issue.reject!
    flash[:notice] = "The issue has been unpublished!"
    redirect_to admin_issues_path
  end

  private
  def fetch_issue
    
    # first check if the issue exists in our system
    issue_id = params[:issue_id] unless params[:issue_id].nil?
    
    response = { :duplicate => false, :text => "" }
    
    @issue = Issue.find_by_issue_id(issue_id)
    # if we were sent here from the confirm_refetch page, user has confirmed they want this issue reingested.
    if @issue && !(params[:confirm_refetch] == 'true')
      # issue was found. confirm that they really really want to reingest
      response[:duplicate] = true
      response[:text] = "The requested issue (#{@issue.source.issue_date}) is already in the system.  Reingesting will overwrite any local changes made to the issue and its articles.  Do you wish to continue?"
    else
      @articles_to_fetch = fetch_article_ids(issue_id)
      if @articles_to_fetch.empty?
        # if there are no articles found, the issue isn't there.
        response[:text] = "Issue not found."
      else
        # fetch the articles from the issue.
        fetch_articles(@articles_to_fetch)
        response[:text] = "Issue ingested successfully."
      end
    end
    
    return response.to_json
  end
  
  # get all the article IDs for the issue (empty array if none found)
  def fetch_article_ids(issue_id)
    Oracle::Article.find(:all, :select => 'id', :conditions => ['issue_id = ?', issue_id])
  end

  # get all the articles. articles_to_fetch is an array of article oracle IDs 
  def fetch_articles(articles_to_fetch)
    articles_to_fetch.each do |article|
      CacmArticle.retrieve(article.id)
    end
  end

end