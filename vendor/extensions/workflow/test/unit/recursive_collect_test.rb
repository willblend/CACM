require File.dirname(__FILE__) + "/../test_helper"

class RecursiveCollectTest < Test::Unit::TestCase
  fixtures :pages
  test_helper :page
  
  def setup
    @page = pages(:homepage)
  end
  
  def test_should_collect_children
    collection = @page.recurse_collecting(&:children).flatten
    all_pages = Page.find(:all, :conditions => "draft_of IS NULL")
    all_pages.each do |page|
      assert collection.include?(page), "Collection does not include '#{page.title}'"
    end
  end
end
