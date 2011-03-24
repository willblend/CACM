# In large part taken from Ticket #502 on the Radiant Trac
module Workflow::Drafts
  class DraftStatus
    def initialize(status)
      @status = status
    end
    
    def name
      self
    end
    
    def id
      @status.id
    end
    
    def to_s
      case @status
      when Status[:draft]
        "...Editing..."
      # when Status[:reviewed]
      #   "...Needs Review..."
      else
        @status.name
      end
    end
    
    def downcase
      "edit-#{@status.name.downcase}"
    end
  end
  
  def self.included(base)
    base.class_eval do
      const_set :NONDRAFT_FIELDS, ["id", "created_by", "updated_by", "draft_of", "lock_version", "parent_id"]
      has_one :draft, :class_name => 'Page', :foreign_key => "draft_of", :dependent => :destroy
      belongs_to :draft_parent, :class_name => 'Page', :foreign_key => "draft_of"
      
      alias_method_chain :find_by_url, :drafts
      alias_method_chain :root, :drafts
      alias_method_chain :children, :drafts
      alias_method_chain :build_draft, :attribute_cloning
      alias_method_chain :status, :drafts
      alias_method_chain :url, :drafts
      alias_method_chain :published?, :drafts
      alias_method_chain :destroy, :drafts
      alias_method_chain :ancestors, :drafts
      
      # Hack needed because we don't have really good access to the validations to remove/replace one
      write_inheritable_attribute :validate, []
      
      # Now restore the default validations and our modified one
      validates_presence_of :title, :slug, :breadcrumb, :status_id, :message => 'required'

      validates_length_of :title, :maximum => 255, :message => '%d-character limit'
      validates_length_of :slug, :maximum => 100, :message => '%d-character limit'
      validates_length_of :breadcrumb, :maximum => 160, :message => '%d-character limit'

      validates_format_of :slug, :with => %r{^([\.\w-]*|/)$}, :message => 'invalid format'
      validates_uniqueness_of :slug, :scope => [:parent_id, :draft_of], :message => 'slug already in use for child of parent'
      validates_numericality_of :id, :status_id, :parent_id, :allow_nil => true, :only_integer => true, :message => 'must be a number'

      validate :valid_class_name
    end
  end
  
  def is_draft?
    self.draft_of
  end
  
  def root_with_drafts
    is_draft? ? draft_parent.root_without_drafts : root_without_drafts
  end

  def url_with_drafts
    is_draft? ? draft_parent.url_without_drafts : url_without_drafts
  end
  
  def status_with_drafts
    if self.draft || is_draft?
      DraftStatus.new((self.draft || self).status_without_drafts)
    else
      status_without_drafts
    end
  end
  
  def published_with_drafts?
    status_id == Status[:published].id
  end
  
  def find_by_url_with_drafts(url, live=true, clean=true)
    return nil if virtual?
    url = clean_url(url) if clean
    my_url = self.url

    if (my_url == url) && (not live or published?)
      return self.draft if !live && self.draft
      self
    elsif (url =~ /^#{Regexp.quote(my_url)}([^\/]*)/)
      slug_child = children.find_by_slug($1)
      if slug_child
        found = slug_child.find_by_url(url, live, clean)
        return found if found
      end
      children.each do |child|
        found = child.find_by_url(url, live, clean)
        return found if found
      end
      file_not_found = self.root.children.find(:first, :conditions => "class_name = 'FileNotFoundPage'")
      return file_not_found.draft if !live && file_not_found && file_not_found.draft
      file_not_found
    end
  end
  
  def children_with_drafts
    is_draft? ? draft_parent.children_without_drafts : children_without_drafts
  end
  
  def build_draft_with_attribute_cloning(attributes={}, replace_existing=true)
    attributes.stringify_keys!
    attrs = self.attributes_before_type_cast.merge('status_id' => Status[:draft].id)
    Page::NONDRAFT_FIELDS.each do |field|
      attrs.delete(field)
    end
    returning build_draft_without_attribute_cloning(attrs.merge(attributes), replace_existing) do |draft|
      self.parts.each do |part|
        part['page_id'] = nil
        draft.parts << part.clone
      end
      clone_associations(draft)
    end
  end
  
  def publish_draft(desired_status=Status[:published])
    if !!is_draft? # Has a draft
      attrs = attributes_before_type_cast.dup
      Page::NONDRAFT_FIELDS.each do |field|
        attrs.delete(field)
      end

      if desired_status.id.eql?(100) # Save and Publish
        # Draft Page saved by save_without_results, promote the draft to live
        try_save_and_return_page(attrs.merge(:status_id => desired_status.id))
      else # Save and Mark for Review / Revert to Edit
        # Draft Page saved by save_without_results, update the status
        self.update_attributes(:status => desired_status)
        return self
      end
    else # No Draft, Real Page
      self.update_attributes(:status => desired_status)
      return self
    end
  end
  
  def try_save_and_return_page(attrs)
    original = self.draft_parent
    original.transaction do
      original.parts.clear
      original.draft.parts.each do |part|
        original.parts << part.clone
      end
      original.publish_associations
      original.reload
      original.draft.destroy
      original.update_attributes(attrs) 
      return original
    end
  end
  
  def destroy_with_drafts
    # Don't destroy the poor children!
    if is_draft?
      destroy_associations
      self.class.delete(self.id)
      self.freeze
    else
      destroy_without_drafts
    end
  end
  
  def destroy_associations
    self.parts.destroy_all
  end
  
  def publish_associations
  end
  
  def clone_associations(draft)
  end
  
  def parent_id_display
    (draft_parent || self).parent_id
  end
  
  def parent_id_display=(value)
    unless is_draft?
      self.parent_id = value
    else
      draft_parent.update_attribute(:parent_id, value)
    end
  end
  
  def ancestors_with_drafts
    is_draft? ? draft_parent.ancestors : ancestors_without_drafts
  end
  
end
