module DpNodeHelper
  include Admin::NodeHelper

  def expander
    if @current_node.parent
      link_to(super, page_index_path(:root => expanded ? @current_node.parent : @current_node))
    else
      "&nbsp;&nbsp;&nbsp;"
    end
  end

end