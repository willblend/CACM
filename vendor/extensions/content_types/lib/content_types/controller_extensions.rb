module ContentTypes::ControllerExtensions
  def self.included(base)
    base.class_eval {
      before_filter :load_content_type, :only => [:new, :edit]
    }
  end
  
  def load_content_type
    unless params[:content_type].blank?
      case params[:content_type].to_i
        when 0
          @content_content_type = ''
          params[:page][:content_type_id] = nil if params[:page]
        else
          @content_content_type = ContentType.find(params[:content_type])
          params[:page][:content_type_id] = @content_content_type.id if params[:page]
      end
    end
  end
end
