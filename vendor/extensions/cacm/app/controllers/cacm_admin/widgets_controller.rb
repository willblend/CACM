class CacmAdmin::WidgetsController < ApplicationController
  only_allow_access_to :new, :edit, :create ,:remove, :index, :safeedit, :destroy,
    :when => CACM::FULL_ACCESS_ROLES,
    :denied_url => {:controller => 'admin/page', :action => 'index'},
    :denied_message => 'You are not authorized to view that page.'
    
  def index
    @widgets = Widget.find(:all, :order => :name)
  end

  def new
    unless params[:clone]
      @widget = Widget.new
    else
      @widget = Widget.find(params[:clone]).clone
    end
  end
  
  def create
    @widget = Widget.new(params[:widget])
    if @widget.save
      redirect_to admin_widgets_path
    else
      flash[:error] = "Your widget could not be saved"
      render :action => :new
    end
  end

  def update
    @widget = Widget.find(params[:id])
    @widget.attributes= params[:widget].merge(:rtag_abstracts => params[:widget_abstracts], :rtag_blocks => params[:tag_blocks])

    if @widget.dewidgetize && @widget.save
      redirect_to admin_widgets_path
    else
      flash[:error] = @widget.error_for_flash ? @widget.error_for_flash : "Your widget could not be saved"
      render :action => :edit
    end
  end

  def safeedit
    @widget = Widget.find(params[:id])
  end

  def edit
    @widget = Widget.find(params[:id])
    unless @widget.widgetize
      flash[:error] = @widget.error_for_flash
      redirect_to safeedit_admin_widget_path(params[:id])
    end
  end

  def destroy
    @widget = Widget.find(params[:id])
    @widget.destroy
    flash[:notice] = "The widget has been deleted"
    redirect_to admin_widgets_path
  end

end