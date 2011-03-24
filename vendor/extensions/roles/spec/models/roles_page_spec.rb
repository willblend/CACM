require File.dirname(__FILE__) + '/../spec_helper'

describe Page do
  scenario :roles
  
  describe ".inherited_roles" do
    before do
      @page = pages(:grandchild)
    end
    it "should find roles in the current page" do
      @page.roles << roles(:editor)
      @page.inherited_roles.should include(roles(:editor))
    end
    
    it "should find roles belonging to an ancestor" do
      pages(:child).roles << roles(:developer)
      @page.inherited_roles.should include(roles(:developer))
    end
    
    it "should not return duplicates" do
      @page.roles << roles(:editor)
      pages(:child).roles << roles(:editor)
      pages(:parent).roles << roles(:editor)
      @page.inherited_roles.should eql([roles(:editor)])
    end
  end
  
end