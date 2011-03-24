module WorkflowHelper
  include Admin::NodeHelper

  def rendering_node(node)
    @current_node = node
  end

  def expanded
    @current_node == @homepage
  end
end