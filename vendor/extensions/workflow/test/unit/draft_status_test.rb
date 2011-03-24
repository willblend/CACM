require File.dirname(__FILE__) + "/../test_helper"

class DraftStatusTest < Test::Unit::TestCase
  def test_should_have_same_id_as_original_status
    [:draft, :review].each do |sym|
      assert_equal Status[sym].id, Workflow::Drafts::DraftStatus.new(Status[sym]).id
    end
  end
  
  def test_should_have_editing_as_its_name
    assert_equal "...Editing...", Workflow::Drafts::DraftStatus.new(Status[:draft]).name.to_s
    assert_equal Status[:review].name.to_s, Workflow::Drafts::DraftStatus.new(Status[:review]).name.to_s
  end
  
  def test_should_have_special_downcase_version_of_name
    [:draft, :review].each do |sym|
      assert_equal "edit-#{sym}", Workflow::Drafts::DraftStatus.new(Status[sym]).name.downcase
    end
  end
end
