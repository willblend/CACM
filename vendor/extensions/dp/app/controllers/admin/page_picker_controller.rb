class Admin::PagePickerController < ApplicationController
  before_filter :load_klass_and_format

  layout 'application_popup.html.erb'
  include Admin::NodeHelper
  
  def index
    per_page = 25
    page = params[:page] ? params[:page] : 1

    @homepage = Page.find(params[:root] || 1)

    if params[:query]
      # Search Fork
      @query = params[:query]
      @filter = params[:filter]
      @results = case params[:search_type]
                 when "filter"
                   if params[:filter] == "0"
                     @results = nil
                   else
                     conditions = ['status_id = ?', params[:filter]]
                     Page.paginate(:all, :conditions => conditions, :per_page => per_page, :page => page)
                   end  
                 
                 when "full-text"
                   if params[:query] == "" || params[:query] == " " || params[:query] == nil
                     @results = nil
                   else
                     Page.site_map_search :query => params[:query], :page => page, :per_page => per_page
                    end
                 end
    end
  end
  
  private
    def load_klass_and_format
      @klass = params[:class].camelize.singularize.constantize
      request.format = params[:format] ||= 'js'
    end  

end