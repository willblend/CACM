module Admin::PagePickerHelper
  include Admin::NodeHelper

  def rendering_node(node)
    @current_node = node
  end

  def expander
    link_to(super, fck_pages_path(:root => expanded ? @current_node.parent : @current_node))
  end

  def expanded
    @current_node == @homepage
  end
end