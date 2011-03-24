module FckHelper

  def page_picker_root_node
    pg = (@page.draft_parent || @page) rescue @page; # resuce in case we're not using the Workflow extension (draft_parent)
    pg = pg.parent if pg.children.empty? && pg.parent

    return pg.id rescue ''
  end

end
