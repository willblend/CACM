module CACM
  module PageControllerExtensions

    def self.included(base)
      base.class_eval {
        alias_method_chain :index, :root
        alias_method_chain :remove, :back
      }
    end

    # view page tree beginning at an arbitary node
    def index_with_root
      if params[:root] # If a root page is specified
        @homepage = Page.find(params[:root])
      else # Just do the default
        index_without_root
      end
    end
    
    # smart redirection to previous node view when a page is removed
    def remove_with_back
      @page = Page.find(params[:id])
      if request.post?
        announce_pages_removed(@page.children.count + 1)
        @page.destroy
        return_url = session[:came_from]
        session[:came_from] = nil
        if return_url && return_url != page_index_url(:root => @page)
          redirect_to return_url
        else
          redirect_to page_index_url(:page => @page.parent)
        end
      else
        session[:came_from] = request.env["HTTP_REFERER"]
      end
    end

  end
end