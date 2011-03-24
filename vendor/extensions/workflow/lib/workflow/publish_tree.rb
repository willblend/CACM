module Workflow::PublishTree
  def publish_tree
    tree = recurse_collecting(&:children).flatten.uniq
    tree.reject(&:is_draft?).each do |page|
      page.draft.publish_draft if page.draft # Pass the draft to publishing if there is one
      page.publish_draft if !page.published? # Pass the page to publishing (updates status) if it isn't published
    end
  end
  
  def unpublish_tree
    tree = recurse_collecting(&:children).flatten
    tree.each do |page|
      page.draft.destroy if page.draft
      page.update_attributes :status => Status[:draft]
    end
  end
end
