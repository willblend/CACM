class WorkflowController < ApplicationController
  helper :workflow
  
  def initialize
    super
    @cache = ResponseCache.instance
  end
  
  def revert
    @page = Page.find(params[:id])
    @page.draft.destroy if @page.draft
    @page.destroy if @page.is_draft?
    announce_changes_reverted
    redirect_to_back_or_default
  end
  
  def publish
    @page = Page.find(params[:id])
    (@page.draft || @page).publish_draft
    announce_page_published
    clear_model_cache
    redirect_to_back_or_default
  end
  
  def publish_tree
    @page = @homepage = Page.find(params[:id])
    if request.post?
      @homepage.publish_tree
      announce_tree_published
      clear_model_cache(true)
      unless params[:root].blank?
        redirect_to page_index_url(:root => params[:root])
      else
        redirect_to page_index_url
      end
    end
  end
  
  def draft_tree
    @page = @homepage = Page.find(params[:id])
    if request.post?
      @homepage.unpublish_tree
      announce_tree_unpublished
      clear_model_cache(true)
      unless params[:root].blank?
        redirect_to page_index_url(:root => params[:root])
      else
        redirect_to page_index_url
      end
    end
  end
  
  def update_status
    @page = Page.find(params[:id])
    @page = @page.draft || @page
    @page.update_attributes(:status_id => params[:status_id])
    redirect_to_back_or_default
  end
  
  protected
    def announce_changes_reverted
      flash[:notice] = %{The working copy of "#{@page.title}" was destroyed.}
    end
    
    def announce_page_published
      flash[:notice] = %{"#{@page.title}" was published and is now live.}
    end
    
    def announce_tree_published
      flash[:notice] = %{"#{@page.title}" and all of its descendant pages were published and are now live.}
    end
    
    def announce_tree_unpublished
      flash[:notice] = %{"#{@page.title}" and all of its descendant pages were reset to draft state.}
    end
  
    def clear_model_cache(cascade = false)
      pages = cascade ? @page.recurse_collecting(&:children).flatten : [@page]
      pages.each do |page|
        @cache.expire_response(page.url)
      end
    end
    
    def redirect_to_back_or_default
      request.env["HTTP_REFERER"] ? redirect_to(:back) : redirect_to(page_index_path)
    end
end
