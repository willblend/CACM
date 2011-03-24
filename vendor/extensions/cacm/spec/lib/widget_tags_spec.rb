require File.dirname(__FILE__) + '/../spec_helper'

describe "Widget Tags" do
  scenario :widgets, :cacm_pages, :cacm_articles

  describe "Dynamic Tag" do
    before do
      @widget_page = pages(:widget_page)
    end

    it "should require a tag attribute" do
      message = %{`dynamic_tag' requires a `tag' attribute}
      @widget_page.should render("<r:dynamic_tag class='awesome'>foo bar</r:dynamic_tag>").with_error(message)
    end

    it "should expand the dynamic_tag" do
      @widget_page.should render("<r:dynamic_tag tag='div' class='awesome' zoot='suit'>foo bar</r:dynamic_tag>").as("<div class=\"awesome\" zoot=\"suit\">foo bar</div>")
    end

    it "should expand the dynamic_tag and render tags nested as attributes" do
      @widget_page.should render("<r:dynamic_tag tag='a' href='r:slug'>title</r:dynamic_tag>").as("<a href=\"widget-page\">title</a>")
    end
  end

  describe "Top Articles" do
    before do
      @widget_page = pages(:widget_page)
    end

    it "should expand top articles" do
      @widget_page.should render("<r:top_articles>foo</r:top_articles>").as("foo")
    end

    it "should iterate over top articles" do
      @widget_page.should render("<r:top_articles><r:each>bar</r:each></r:top_articles>").as("bar" * 5)
    end

    it "should iterate and expand titles and provide links" do
      @widget_page.stub!(:contextual_article_path).and_return("/")
      @widget_page.stub!(:current_member).and_return(mock('Session', :can_access? => true))
      articles = "Crystallography: Awesome/Super Computing: Awesome/Zero Sum Games: Awesome/Histone Acetylation: Awesome/Article Stub: Awesome/"
      @widget_page.should render("<r:top_articles><r:each><r:title>foo</r:title><r:link>bar</r:link></r:each></r:top_articles>").as(articles)
    end
  end
  
  describe "Placeholder" do
    it "should yield" do
      pages(:widget_page).should render('<r:placeholder attr="dummy">Content</r:placeholder>').as('Content')
    end
  end

end