require File.dirname(__FILE__) + "/../test_helper"

class PageDraftsTest < Test::Unit::TestCase

  def setup
    @page = pages(:homepage)
    @user = users(:another)
    UserActionObserver.current_user = @user
  end

  def test_is_draft
    assert !@page.is_draft?
    assert @page.build_draft.is_draft?
  end

  def test_url_with_drafts
    @page = pages(:documentation)
    assert_equal @page.url, @page.draft.url
  end
  
  def test_published_with_drafts
    @page = pages(:documentation)
    assert_not_nil @page.draft
    assert @page.published?
  end
  
  def test_status_with_drafts
    assert_equal @page.status, Status[:published]
    @page.build_draft
    assert_kind_of Workflow::Drafts::DraftStatus, @page.status
    assert_equal @page.status.id, Status[:draft].id
    assert_equal "...Editing...", @page.status.name.to_s
    assert_equal "edit-draft", @page.status.name.downcase
    
    @page = pages(:documentation)
    assert_kind_of Workflow::Drafts::DraftStatus, @page.status
    assert_equal @page.status.id, Status[:draft].id
    assert_equal "...Editing...", @page.status.name.to_s
    assert_equal "edit-draft", @page.status.name.downcase    
  end
  
  def test_find_by_url_with_drafts
    draft = pages(:assorted).build_draft
    draft.save!
    assert @page.find_by_url('/assorted', false).is_draft?
    assert_not_nil @page.find_by_url('/assorted')
    assert !@page.find_by_url('/assorted').is_draft?
  end
  
  def test_find_non_draft_when_live
    expected = pages(:documentation)
    found = @page.find_by_url("/documentation")
    assert_equal expected, found
    assert !found.is_draft?
  end
  
  def test_find_by_url_when_not_found_draft
    found = @page.find_by_url('/gallery/asdf', false)
    assert_instance_of FileNotFoundPage, found
    assert found.is_draft?
  end
    
  def test_destroy_draft_dependent
    @page = pages(:documentation)
    assert_not_nil @page.draft
    draft_id = @page.draft.id
    @page.destroy
    assert_raises(ActiveRecord::RecordNotFound){
      Page.find(draft_id)
    }
  end
  
  def test_build_draft
    @page = pages(:books)
    
    draft = @page.build_draft
    [:title, :slug, :breadcrumb].each do |attr|
      assert_equal @page[attr], draft[attr]
    end
    [:created_by, :updated_by].each do |attr|
      assert_nil draft[attr]
    end
    
    assert_equal Status[:draft].id, draft.status_id
    assert_equal @page.id, draft.draft_of
    assert_equal @page.parts.size, draft.parts.size
    assert draft.new_record?
    assert_valid draft
    
    # Pass it attributes to override
    draft = @page.build_draft(:title => "Changed title")
    assert_equal "Changed title", draft.title
    assert_equal @page.slug, draft.slug
    
    # UserActionObserver should work with drafts
    assert draft.save
    assert_equal @user, draft.created_by
    draft.reload
    assert draft.update_attributes(:title => "something different")
    assert_equal @user, draft.updated_by
  end
  
  def test_publish_draft_when_standalone_draft
    @page = pages(:article_draft)
    assert !@page.is_draft?
    assert_equal Status[:draft], @page.status
    
    @page.publish_draft
    assert_equal Status[:published], @page.status
  end
  
  def test_publish_draft_when_draft_of_published_page
    @page = pages(:documentation)
    expected_content = page_parts(:documentation_draft_body).content
    original_creator = @page.created_by
    
    assert_not_nil @page.draft
    @page.publish_draft
    assert_nil @page.draft
    @page.reload
    assert_equal expected_content, @page.parts.first.content
    assert_equal Status[:published], @page.status
    assert_equal original_creator, @page.created_by
    assert_equal @user, @page.updated_by
  end
  
  def test_publish_draft_when_desired_status_other_than_published
    @page = pages(:documentation)
    
    assert_not_nil @page.draft
    assert_not_equal Status[:hidden].id, @page.draft.status_id
    @page.publish_draft(Status[:hidden])
    @page.reload
    assert_equal Status[:hidden], @page.status
    assert_nil @page.draft
  end
  
  def test_destroy_draft_does_not_clobber_children
    @page = pages(:documentation)
    count = @page.children.count
    @page.draft.destroy
    @page.reload
    assert_equal count, @page.children.count
  end
  
  def test_parent_id_display_assignment_updates_draft_parent
    @page = pages(:documentation_draft)
    @page.parent_id_display = pages(:textile).id
    assert_equal pages(:textile).id, pages(:documentation_draft).draft_parent.reload.parent_id
  end
  
  def test_parent_id_display_taken_from_draft_parent
    @page = pages(:documentation_draft)
    assert_equal pages(:documentation).parent_id, @page.parent_id_display
  end
  
  def test_parent_id_display_assignment_updates_parent_id_on_non_draft
    @page = pages(:books)
    @page.parent_id_display = pages(:textile).id
    assert_equal pages(:textile).id, @page.parent_id
  end
  
  def test_parent_id_display_same_as_parent_id_on_non_draft
    assert_equal pages(:books).parent_id, pages(:books).parent_id_display
  end
  
  def test_draft_should_work_on_404_page
    @page = pages(:file_not_found_draft) 
    @draft_parent = @page.draft_parent 
    assert @page.is_draft? 
    assert_not_nil @draft_parent 
    @page.parts.clear 
    assert_difference @page.parts, :count do 
      @page.parts << PagePart.new(:name => "body", :content => "Testing!") 
      assert @page.save, "#{@page.errors.full_messages.to_sentence}" 
      @page.parts(false) 
    end
    assert_no_difference PagePart, :count do
      assert @page.publish_draft
    end
    assert_equal 1, @draft_parent.parts.count 
    assert_not_nil @draft_parent.part("body") 
    assert_equal 'Testing!', @draft_parent.part("body").content 
  end 
  
  def test_ancestors_with_drafts
    @page = pages(:great_grandchild)
    assert_equal @page.ancestors, @page.build_draft.ancestors
  end
end
