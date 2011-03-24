class AssetsController < ApplicationController
  include ActionView::Helpers::TextHelper

  # handle viewing the asset manager in different contexts
  layout :layout_for_request_type

  # SWFUpload mods
  session :cookie_only => false, :only => [:create, :update]
  before_filter :coerce_swf_upload, :only => [:create, :update]

  before_filter do |c|
    c.include_stylesheet  'admin/asset_manager'

    c.include_javascript  'lowpro'
    c.include_javascript  'prototype_extensions'
    c.include_javascript  'admin/DatePicker'
    c.include_javascript  'admin/swfupload'
    c.include_javascript  'admin/swfupload.swfobject.js'
    c.include_javascript  'admin/swfupload_adapter'
    c.include_javascript  'livepipe'
    c.include_javascript  'livepipe.window.js'
    c.include_javascript  'livepipe.progressbar.js'

    c.params[:format] ||= 'html'
    c.params[:type]   ||= 'all'
  end
  
  # handle choosing different asset types
  before_filter :set_asset_klass
  
  def browse
    @assets = case
      when params[:search]
        conditions = @klass == Asset ? nil : { :conditions => { :class_name => @klass.name } }
        Asset.search("*#{params[:search]}*", params[:page], conditions)
      when params[:index]
        @klass.find_all_by_index(params[:index], params[:page])
      else
        @klass.paginate(:page => params[:page], :order => :file_file_name)
    end
  end
  
  def recent
    @assets = @klass.paginate(:page => params[:page], :order => 'created_at DESC')
  end
  
  def report
    @assets = @klass.find_expired(params[:page])
  end
  
  def show
    @asset = Asset.find(params[:id])
    render :action => :edit
  end
  
  def new
    @asset = Asset.new
  end
  
  def create
    @asset = Asset.new(params[:asset])
    @asset.uploaded_by_id = current_user.id
    @asset = @asset.to_zip if @asset.zip? && params[:unzip_asset]

    if @asset.save
      flash.now[:notice] = "#{@asset.file_file_name} uploaded."

      # swfUpload response
      if params[:flash_upload]
        if params[:format] == "html"
          render :partial => "asset_row", :object => @asset
        else
          render :partial => "asset_row_picker", :object => @asset
        end

      # standard FORM response
      else
        redirect_to @asset.zip? ? recent_assets_path(:format => params[:format], :type => params[:type]) : 
                                  edit_asset_path(:id => @asset.id, :format => params[:format], :just_created => 1, :type => params[:type])
      end

    else
      if params[:flash_upload]
        flash.now[:error] = @asset.zip? ?  "Failed to extract #{pluralize @asset.failures.size, 'asset'}" : "There was an error uploading #{@asset.file_file_name}"
      end

      # swfUpload response
      if params[:flash_upload]
        head(500)

      # standard FORM response
      else
        render :action => 'new'
      end
    end
  end
  
  def edit
    @asset = Asset.find(params[:id])
    @asset_usage = @asset.used_in
  end
  
  def update
    @asset = Asset.find(params[:id])
    if @asset.update_attributes(params[:asset])
      if params[:commit] =~ /replace/i
        flash[:notice] = "#{@asset.file_file_name} replaced."
        redirect_to edit_asset_path(:id => @asset.id, :format => params[:format], :type => params[:type])
      else
        flash[:notice] = "#{@asset.file_file_name} updated."
        redirect_to recent_assets_path(:format => params[:format], :type => params[:type])
      end
    else
      flash[:error] = 'Please correct the errors below.'
      render(:action => :edit)
    end
  end
  
  def destroy
    @asset = Asset.find(params[:id])
    file_name = @asset.file_file_name
    if @asset.destroy
      flash[:notice] = "#{file_name} was deleted"
    else
      flash[:error] = "Could not delete #{file_name}"
    end
    redirect_to recent_assets_path(:format => params[:format], :type => params[:type])
  end
  

  protected
    def layout_for_request_type
      case params[:format]
      when 'fck', 'rad' : 'application_popup.html.erb'
      else 'application.html.haml'
      end
    end
    
    def coerce_swf_upload
      if params[:Filedata]
        params[:asset] ||= {}
        params[:asset][:file] = params[:Filedata]
      end
    end
    
    def set_asset_klass
      @klass = case params[:type].to_s
               when /^all$/i : Asset
               when /^recent$/i : Asset
               when /^report$/i : Asset
               else (params[:type].camelcase + 'Asset').constantize
               end
    end
    
end
