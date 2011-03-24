class WidgetsScenario < Scenario::Base
  
  def load
    create_widget :teeny_widget do 
      "<div class='teeny'>teeny widget</div>"
    end

    create_widget :tiny_widget do 
      "<div class='tiny'>tiny widget</div>"
    end

    create_widget :any_widget do 
      "<div class='content'>
        <h3>Some stuff</h3>
        <r:any_tag properties='width:200px;height:50px;' anyattr='10'>
          <ul>
          <r:each>
            <li>Iterated</li>
          </r:each>
          </ul>
        </r:any_tag>
      </div>"
    end

    create_widget :ugly_widget do 
      "<r:any_tag properties='width:200px;height:50px;' anyattr='10'><div class='<r:illegaly_nested rtag='true' />'><r:any_title /></div></r:any_tag>"
    end

    create_widget :bad_widget do 
      "<r:any_tag properties='width:200px;height:50px;' anyattr='10'>
        <h3><r:any_title /></h3>
        <ul>
        <r:each>
          <li>Iterated</li>"
    end
  end
  
  private
  def base_widget
    { :created_by_id => 1, :updated_by_id => nil, :created_at => Time.now, :updated_at => nil  }
  end

  def create_widget(name, &block)
    create_record Widget, name, base_widget.merge(:name => name.to_s, :content => yield)
  end
end