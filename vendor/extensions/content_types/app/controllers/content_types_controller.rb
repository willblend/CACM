class ContentTypesController < ApplicationController
  # A hack, but the only way it works in something other than dev mode
  write_inheritable_attribute :resourceful_callbacks, {}
  write_inheritable_attribute :resourceful_responses, {}
  write_inheritable_attribute :parents,               []

  only_allow_access_to :index, :new, :edit, :create, :update, :destroy,
    :when => CACM::ADMIN_ACCESS_ROLES,
    :denied_url => { :controller => 'admin/page', :action => 'index' },
    :denied_message => 'You must have developer privileges to perform this action.'

  make_resourceful do
    actions :index, :new, :create, :edit, :update, :destroy
    
    response_for(:create, :update, :destroy, :destroy_fails) do |format|
      format.html { redirect_to objects_path }
    end
  end
  
  # Ordering actions
  %w{move_higher move_lower move_to_top move_to_bottom}.each do |action|
    define_method action do
      load_object
      ContentType.reordering do
        current_object.send(action)
      end
      request.env["HTTP_REFERER"] ? redirect_to(:back) : redirect_to(objects_path)
    end
  end
  
  
  def instance_variable_name
    'content_content_types'
  end
end
