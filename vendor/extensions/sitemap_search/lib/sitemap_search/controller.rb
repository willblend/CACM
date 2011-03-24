module SitemapSearch::Controller
    
  def search
    # Kick user back to home page or apply filter or ft search
    case params[:search_type]
    when "filter"
      redirect_to page_index_path and return if params[:filter] == "0"
      @results = Page.find(:all, :conditions => ['status_id = ?', params[:filter]])
    when "full-text"
      redirect_to page_index_path and return if params[:query].blank?
      @results = Page.search params[:query], :page => params[:page]
    end
  end
  
  
end
