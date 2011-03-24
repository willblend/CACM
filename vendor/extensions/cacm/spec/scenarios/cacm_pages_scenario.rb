class CacmPagesScenario < Scenario::Base
  uses :home_page
  uses :widgets
  
  def load
    create_page "missing widget page" do
      create_page_part "missing_widget_column", :content => "100"
    end

    create_page "widget page" do
      create_page_part "widget_column", :content => "#{widgets(:teeny_widget).id},#{widgets(:teeny_widget).id},#{widgets(:tiny_widget).id}"
    end

    create_page "no widget page" do
      create_page_part "side_column", :content => "some stuff"
    end
    
    create_page "browse by subject" do
      create_page "Artificial Intelligence" do
      end
    end
    
    create_page "opinion" do
      create_page "articles"
    end

    create_page "blogs" do
      create_page "blog cacm"
    end
    
    create_page "news" do
      
    end
    create_page "careers" do
      
    end
    
    create_page "magazines" do
      
    end

  end

end