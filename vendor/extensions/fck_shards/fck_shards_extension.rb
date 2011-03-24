# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class FckShardsExtension < Radiant::Extension
  version "0.25"
  description "Adds FCKeditor to text areas in the page edit screen."
  url "http://svn.digitalpulp.com/radiant/extensions/fck_shards"

  define_routes do |map|
  end
  
  def activate
    Admin::PageController.class_eval{ helper :fck }
    ApplicationController.class_eval{ helper :fck }

    # add in then necessary JS to allow FCK Editor display
    ApplicationController.send  :include, FCK::AdminUIExtensions

    # add FCK Editor controls to Radiant page edit screen
    admin.page.edit.add :main, "fck_editor", :before => "edit_header"
  end
  
  def deactivate
  end
  
end
