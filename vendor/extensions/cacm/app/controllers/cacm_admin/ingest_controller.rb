class CacmAdmin::IngestController < ApplicationController
  only_allow_access_to :create,
    :when => CACM::FULL_ACCESS_ROLES,
    :denied_url => {:controller => 'admin/page', :action => 'index'},
    :denied_message => 'You are not authorized to view that page.'
  
  def create
    unless params[:id].blank?
      case
      when local = DLArticle.find_by_oracle_id(params[:id]), local = DLArticle.find_by_uuid(params[:id])
        flash.now[:error] = "A DL Article with DOI #{params[:id]} has already been ingested. <a href='" + edit_admin_article_path(local) + "'>Edit?</a>"
        render :action => 'new' and return
      when local = Feed.find(CACM::DL_FEED_ID).ingest(params[:id])
        flash[:notice] = 'New article created.'
        redirect_to edit_admin_article_path(local) and return
      end
    end
    
    flash.now[:error] = 'No DL Article found with that ID.'
    render :action => 'new'
  end
end
