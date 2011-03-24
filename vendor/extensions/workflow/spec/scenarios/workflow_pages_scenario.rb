class WorkflowPagesScenario < Scenario::Base
  uses :home_page
  def load

    create_page "First Area", :status_id => 100 do
      create_page "Page 1", :status_id => 100
      create_page "Page 2", :status_id => 100
      create_page "Page 3", :status_id => 50
      create_page "Page 4", :status_id => 1
    end
    create_page "Second Area", :status_id => 1 do
      create_page "Page 5", :status_id => 100
      create_page "Page 6", :status_id => 100
    end
    create_page "Third Area", :status_id => 1 do
      create_page "Page 7", :status_id => 1
      create_page "Page 8", :status_id => 1
    end

    create_page "Page 2 Draft", :status_id => 1, :draft_of => pages(:page_2).id, :parent_id => nil
    create_page "Page 5 Draft", :status_id => 50, :draft_of => pages(:page_5).id, :parent_id => nil
    create_page "Page 6 Draft", :status_id => 1, :draft_of => pages(:page_6).id, :parent_id => nil

  end
end