# These methods use the association stubs present in workflow

module DP
  module DraftExtensions
  
    def self.included(base)
      base.class_eval do
        alias_method_chain :destroy_associations, :page_relations
        alias_method_chain :publish_associations, :page_relations
        alias_method_chain :clone_associations, :page_relations
      end
    end
  
    def destroy_associations_with_page_relations
      page_relations.destroy_all
      destroy_associations_without_page_relations
    end

    def publish_associations_with_page_relations
      self.page_relations = self.draft.page_relations
      publish_associations_without_page_relations
    end

    def clone_associations_with_page_relations(draft)
      clone_associations_without_page_relations(draft)
      page_relations.each do |r|
        draft.page_relations << r.clone
      end
    end
  
  end
end