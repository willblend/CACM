require File.dirname(__FILE__) + '/../spec_helper'

describe Widget do
  scenario :widgets, :cacm_pages

  describe "rendering" do
    before(:each) do
      @missing_widget_page = pages(:missing_widget_page)
      @widget_page = pages(:widget_page)
      @no_widget_page = pages(:no_widget_page)
    end

    it "should render widgets whose ids are stored in a page part" do
      @widget_page.should render("<r:widgets part='widget_column' />").as("<div class='teeny'>teeny widget</div><div class='teeny'>teeny widget</div><div class='tiny'>tiny widget</div>")
    end

    it "should gracefully handle missing widgets" do
      @missing_widget_page.should render("<r:widgets part='missing_widget_column' />").as("")
    end

    it "should raise an error when a part is not specified" do
      message = %{`widgets` tag must contain `part` attribute}
      @no_widget_page.should render("<r:widgets />").with_error(message)
    end

    it "should render an explicitly called widget" do
      @widget_page.should render("<r:widget name='teeny_widget' />").as(widgets(:teeny_widget).content)
    end

    it "should raise an error when it can't find the named widget" do
      message = %{widget not found}
      @widget_page.should render("<r:widget name='absent_widget' />").with_error(message)
    end

    it "should raise an error when no name is specified" do
      message = %{`widget' tag must contain `name' attribute}
      @widget_page.should render("<r:widget />").with_error(message)
    end
  end
  
  describe "widgetizing" do
    it "should fail to render malformed content" do
      @widget = widgets(:ugly_widget)
      @widget.widgetize.should be_false
    end

    it "should fail to prematurely terminated content" do
      @widget = widgets(:bad_widget)
      @widget.widgetize.should be_false
    end

    it "should widgetize and handle all this yaml biznass" do
      yaml_attributes = {"attributes" => {"anyattr" => {"legend" => "This is an example of a text field. I am helper text.", "input" => "text"}}}

      Page.stub!(:tag_descriptions).and_return({"any_tag" => yaml_attributes})
      YAML.stub!(:load).and_return(yaml_attributes)
      
      @widget = widgets(:any_widget)
      @widget.widgetize.should be_true
    end

  end

  describe "dewidgetizing" do
    before(:each) do
      # This fakes the desc block in the widget tags
      yaml_attributes = {"attributes" => {"anyattr" => {"legend" => "This is an example of a text field. I am helper text.", "input" => "text"}}}
      
      # This fakes what form produces and what will be received on post
      form_attributes = {"any_tag" => {"anyattr" => "8"}}

      Page.stub!(:tag_descriptions).and_return({"any_tag" => yaml_attributes})
      YAML.stub!(:load).and_return(yaml_attributes)

      @widget = widgets(:any_widget)
      @widget.widgetize
      @widget.rtag_blocks     = DP::Spec.fake_form_post(@widget.rtag_blocks)
      @widget.rtag_abstracts  = form_attributes

    end

    it "should not return any errors on a legit save" do
      @widget.fck_content = "<div class=\"content\"><h3>Some other stuff</h3><img style=\"width:200px;height:50px;\" src=\"/images/grey.gif\" alt=\"widget replacement\" id=\"fck-widget-0\"/></div>"
      @widget.dewidgetize.should be_true
    end

    it "should not allow you to remove an image" do
      @widget.fck_content = "<div class=\"content\"><h3>Some other stuff</h3>I done removed it</div>"
      @widget.dewidgetize.should be_false
    end

    it "should not allow you to save malformed content" do
      @widget.fck_content = "<h3>Some other stuff</h3><img style=\"width:200px;height:50px;\" src=\"/images/grey.gif\" alt=\"widget replacement\" id=\"fck-widget-0\"/></div>"
      @widget.dewidgetize.should be_false
    end

  end
end