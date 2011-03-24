module PreviewControllerExtensions
  def self.included(base)
    base.class_eval { 
      helper_method :preview_links 
      around_filter :nullify_page_scope, :only => :preview
    }
  end

  def preview
    @page = Page.find(params[:id])
    (@page.draft || @page).process(request, response)
    @performed_render = true

  end

  def preview_links(page)
    returning [] do |output|
      if page.draft || !page.published?
        preview_url = @site ? @site.dev_url(page.url) : page_preview_path(:id => page)
        output << @template.link_to("Preview", preview_url, :target => "_blank")
      end
      if page.published?
        live_url = @site ? @site.url(page.url) : page.url
        output << @template.link_to("Live", live_url, :target => "_blank")
      end
    end.join(" &bull; ")
  end

  def nullify_page_scope
    Page.send(:with_exclusive_scope, :find => {:conditions => nil} ) do
      yield
    end
  end
end