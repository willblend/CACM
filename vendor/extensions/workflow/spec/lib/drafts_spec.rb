require File.dirname(__FILE__) + '/../spec_helper'

describe Workflow do
  scenario :workflow_pages

  describe "test assumptions" do
    specify "pages 2, 5, and 6 should have a drafts" do
      pages(:page_2).draft.should_not be_nil
      pages(:page_5).draft.should_not be_nil
      pages(:page_6).draft.should_not be_nil
    end

    specify "other pages should not have drafts" do
      pages(:first_area).draft.should be_nil
      pages(:second_area).draft.should be_nil

      pages(:page_1).draft.should be_nil
      pages(:page_3).draft.should be_nil
      pages(:page_4).draft.should be_nil
    end
  end

  describe "status changes for pages with drafts" do
    it "should allow the publishing of drafts and removal of the same post-publishing" do
      result = pages(:page_2).draft.save # Emulate the save_without_drafts behavior in PageControllerExtensions
      promote = pages(:page_2).draft.publish_draft(Status[:published])
      pages(:page_2).reload.title.should eql("Page 2 Draft")
      pages(:page_2).reload.draft.should be_nil
    end

    it "should allow the publishing of reviewed drafts and removal of the same post-publishing" do
      result = pages(:page_5).draft.save # Emulate the save_without_drafts behavior in PageControllerExtensions
      promote = pages(:page_5).draft.publish_draft(Status[:published])
      pages(:page_5).reload.title.should eql("Page 5 Draft")
      pages(:page_5).reload.draft.should be_nil
    end

    it "should allow switching between drafted states" do
      # Edit => Mark for Review
      pages(:page_6).draft.publish_draft(Status[:review])
      pages(:page_6).reload.draft.status.id.should eql(Status[:review].id)

      # Now revert
      pages(:page_6).draft.publish_draft(Status[:draft])
      pages(:page_6).reload.draft.status.id.should eql(Status[:draft].id)
    end

  end

  describe "status changes for pages without drafts" do
    it "should allow switching between drafted states" do
      pages(:second_area).published?.should be_false
      pages(:second_area).publish_draft(Status[:review])
      pages(:second_area).reload.status.id.should eql(Status[:review].id)

      # Now revert
      pages(:second_area).publish_draft(Status[:draft])
      pages(:second_area).reload.status.id.should eql(Status[:draft].id)
    end

    it "should allow publishing from a drafted state" do
      pages(:second_area).publish_draft
      pages(:second_area).reload.published?.should be_true
    end
  end

  describe "mass actions" do
    it "should allow recursive publishing of a tree of pages" do
      pages(:third_area).publish_tree
      [pages(:third_area)].rcollect(&:children).flatten.each do |page|
        page.published?.should be_true
      end
    end

    it "should allow recursive unpublishing of a tree of pages" do
      pages(:third_area).unpublish_tree
      [pages(:third_area)].rcollect(&:children).flatten.each do |page|
        page.published?.should_not be_true
      end
    end
  end

end