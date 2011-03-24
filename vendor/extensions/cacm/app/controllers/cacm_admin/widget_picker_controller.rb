class CacmAdmin::WidgetPickerController < ApplicationController
  only_allow_access_to :associated_widgets, :build_widget_parts,
    :when => CACM::FULL_ACCESS_ROLES,
    :denied_url => {:controller => 'admin/page', :action => 'index'},
    :denied_message => 'You are not authorized to view that page.'
  
  
  include ActionView::Helpers::JavaScriptHelper
  layout "application_popup.html.erb"
  
  def associated_widgets
    respond_to do |format|
      
      format.html do
        @widgets = Widget.find(:all)
        render :action => :index
      end
      
      format.js do
        widgets = build_widget_parts(params[:data].split(','))
        render :text => ("[" + widgets + "]").to_json
      end
            
    end
  end
  
  def build_widget_parts(data)
    returning [] do |output|
      params[:data].split(",").each do |widget_data|
        raw_widget_data = widget_data.split("|")
        if raw_widget_data.size.eql?(1) && !widget_data.include?("|")
          widget = Widget.find(widget_data) rescue nil
          output << { :id => widget.id, :title => escape_javascript(widget.name.titleize) }.to_json if widget
        elsif raw_widget_data.size.eql?(2) || widget_data.include?("|")
          widget = Widget.find(widget_data.to_i) rescue nil
          output << { :id => widget.id, :title => escape_javascript(widget.name.titleize), :inner_content => "<input type=\"text\" class=\"associated-article-field associated-value\" value=\"#{raw_widget_data[1]}\" />" }.to_json if widget
        else
          raise "Too many pipes!" if raw_widget_data.size > 2
        end
      end
    end.join(",")
  end

end