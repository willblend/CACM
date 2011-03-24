module Workflow::PageControllerExtensions
  def self.included(base)
    base.class_eval do
      alias_method_chain :edit, :drafts
      alias_method_chain :save, :drafts
      alias_method_chain :index, :drafts
      around_filter :hide_draft_pages, :except => [:edit, :index, :children, :remove]
    end
  end

  def index_with_drafts
    Page.send(:with_scope, :find => {:conditions => {:draft_of => nil}}) do
      index_without_drafts
    end
  end

  def edit_with_drafts
    @page = Page.find(params[:id])
    @old_page_url = @page.url
    @page = @page.draft || @page.build_draft if @page.published?
    handle_new_or_edit_post
  end
  
  def save_with_drafts
    result = save_without_drafts
    if result
      promote = model.publish_draft(Status[:published]) if params[:publish]
      promote = model.publish_draft(Status[:review]) if params[:review]
      promote = model.publish_draft(Status[:draft]) if params[:draft]
    end
    if promote && promote.errors.any?
      promote.errors.map {|x| model.errors.add(x[0],x[1])}
      false
    else
      result
    end
  end
  
  def hide_draft_pages
    Page.send(:with_scope, :find => {:conditions => "draft_of IS NULL"}) do
      yield
    end
  end
end
