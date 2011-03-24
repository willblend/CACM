require File.dirname(__FILE__) + '/../spec_helper'

describe "CACM Radius Tags" do
  scenario :cacm_pages, :subjects, :sections, :articles_base

  before do
    @widget_page = pages(:widget_page)
  end

  describe 'Header Tags' do
    
    it "should expand the if_logged_in tag if logged in" do
      @member = mock(:member)
      @member.stub!(:indv?).and_return(true)
      @widget_page.stub!(:current_member).and_return(@member)
      @widget_page.should render("<r:if_logged_in>foo bar</r:if_logged_in>").as("foo bar")
    end
  
    it "should not expand the if_logged_in tag if not logged in" do
      @member = mock(:member)
      @member.stub!(:indv?).and_return(false)
      @widget_page.stub!(:current_member).and_return(@member)
      @widget_page.should render("<r:if_logged_in>foo bar</r:if_logged_in>").as("")
    end
  
    it "should expand the unless_logged_in tag if logged in" do
      @member = mock(:member)
      @member.stub!(:indv?).and_return(true)
      @widget_page.stub!(:current_member).and_return(@member)
      @widget_page.should render("<r:unless_logged_in>foo bar</r:unless_logged_in>").as("")
    end
  
    it "should not expand the unless_logged_in tag if not logged in" do
      @member = mock(:member)
      @member.stub!(:indv?).and_return(false)
      @widget_page.stub!(:current_member).and_return(@member)
      @widget_page.should render("<r:unless_logged_in>foo bar</r:unless_logged_in>").as("foo bar")
    end
  
    it "should return the current_member's name if there is one" do
      @member = mock(:member)
      @member.stub!(:name).and_return("fred")
      @widget_page.stub!(:current_member).and_return(@member)
      @widget_page.should render("<r:current_username />").as("fred")
    end
  
    it "should return the current_member's username if the member has no name" do
      @member = mock(:member)
      @member.stub!(:name).and_return(nil)
      @member.stub!(:username).and_return("fred_thompson")
      @widget_page.stub!(:current_member).and_return(@member)
      @widget_page.should render("<r:current_username />").as("fred_thompson")
    end
  
  end
  
  describe 'RSS tags' do
    it "should render the opinion rss feed" do
      pages(:opinion).should render("<r:rss_link_tag />").as(/.*\/opinion.rss.*/)
    end
    it "should render the blogs rss feed" do
      pages(:blogs).should render("<r:rss_link_tag />").as(/.*\/blogs\/blog-cacm.rss.*/)
    end
    it "should render the careers rss feed" do
      pages(:careers).should render("<r:rss_link_tag />").as(/.*\/careers.rss.*/)
    end
    it "should render the news rss feed" do
      pages(:news).should render("<r:rss_link_tag />").as(/.*\/news.rss.*/)
    end
    it "should render the magazine feed" do
      pages(:magazines).should render("<r:rss_link_tag />").as(/.*\/magazine.rss.*/)
    end
  
    it "should render a browse-by-subject feed" do
      pages(:artificial_intelligence).should render("<r:rss_link_tag />").as(/.*\/browse-by-subject\/artificial-intelligence.rss.*/)
    end
    
    it "should return the correct subject rss url" do
      pages(:artificial_intelligence).should render("<r:subject_rss_url />").as("/browse-by-subject/artificial-intelligence.rss")
    end
    
    it "should return the magazine feed from the homepage" do
      pages(:home).should render("<r:rss_link_tag />").as(/.*\/magazine.rss.*/)
    end
  end

  describe 'Latest Articles' do
    
    describe 'Browse By Subject' do
      before(:each) do
        @page = pages(:artificial_intelligence)
        @a = Article.find(:all, :limit => 3)
  
        @a.each do |art|
          art.subjects << Subject.find_by_name("artificial intelligence")
          art.approve!
          art.save
        end
      end
      
      it "should only show approved articles" do
        @a[0].reject! # reject one of 'em
        a = @a[1]
        a.approved_at = Time.now
        a.save
        a = @a[2]
        a.approved_at = 1.day.ago
        a.save
        urls = @a.collect{|art| art.approved? ? "/browse-by-subject/artificial-intelligence/#{art.to_param}" : nil}.compact.to_s
        @page.should render("<r:latest_articles><r:each><r:url/></r:each></r:latest_articles>").as(urls)
      end
      
      it "should show articles in order of approval date" do
        a = @a[0]
        a.approved_at = 1.week.ago
        a.save
        a = @a[1]
        a.approved_at = 1.month.ago
        a.save
        a = @a[2]
        a.approved_at = Time.now
        a.save
        urls = [2,0,1].collect{|a| "/browse-by-subject/artificial-intelligence/#{@a[a].to_param}"}.compact.to_s
        @page.should render("<r:latest_articles><r:each><r:url/></r:each></r:latest_articles>").as(urls)
      end
    end
    
    describe 'Sections' do
      before(:each) do
        @page = pages(:articles)
      end
      
      it "should only show approved articles" do
        @a = Section.find_by_name("opinion").articles
        @a[0].reject!
        urls = @a.collect{|art| art.approved? ? "/opinion/articles/#{art.to_param}" : nil}.compact.to_s
        @page.should render("<r:latest_articles><r:each><r:url/></r:each></r:latest_articles>").as(urls)        
      end
    end
  end

  describe 'featured summary' do
    it "should not expand if there is no featured article" do
      @page = pages(:articles)
      @page.should render("<r:featured_summary />").as("")
    end
  end

  describe 'CACM page title' do
    describe 'Rails pages' do
      before do
        @page = RailsPage.new
        @page.title = "foo"
        @page.slug = "1234-foo"
        @page.save
      end
      
      it "should render archives index title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'archives'
        @request.path_parameters[:action] = 'index'
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("Magazine Archive | Communications of the ACM")
      end

      it "should render archive toc title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'archives'
        @request.path_parameters[:action] = 'toc'
        @request.parameters[:month] = '12'
        @request.parameters[:year] = '2020'
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("December 2020 Table of Contents | Communications of the ACM")
      end

      it "should render archive year title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'archives'
        @request.path_parameters[:action] = 'year'
        @request.parameters[:year] = '2020'
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("2020 Issues | Communications of the ACM")
      end

      it "should render a magazine article title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'magazines'
        @request.parameters[:month] = '12'
        @request.parameters[:year] = '2020'
        @request.parameters[:article] = Article.find(:first).id
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("#{Article.find(:first).title} | December 2020 | Communications of the ACM")
      end

      it "should render a browse-by-subject article title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'subjects'
        @request.parameters[:subject] = Subject.find(:first)
        @request.parameters[:article] = Article.find(:first).id
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("#{Article.find(:first).title} | #{Subject.find(:first).name.titleize} | Communications of the ACM")
      end

      it "should render a article by section title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'sections'
        @request.parameters[:section] = Section.find(:first)
        @request.parameters[:article] = Article.find(:first).id
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("#{Article.find(:first).title} | #{Section.find(:first).name.titleize} | Communications of the ACM")
      end

      it "should render search results title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'search'
        @request.parameters[:q] = "Vardi"
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("Search results for \"Vardi\" | Communications of the ACM")
      end

      it "should render sign in page title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'session'
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("Sign In | Communications of the ACM")
      end

      it "should render create accounts page title" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'accounts'
        @request.path_parameters[:action] = 'new'
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("Create a Web Account | Communications of the ACM")
      end

      it "should render forgot password accounts page titles" do
        @request = ActionController::TestRequest.new
        @request.path_parameters[:controller] = 'accounts'
        @request.path_parameters[:action] = 'forgot'
        @page.stub!(:request).and_return(@request)
        @page.should render("<r:cacm_page_title />").as("Forgot Your Password | Communications of the ACM")
      end

      it "should default to Communications of the ACM" do
        @page.should render("<r:cacm_page_title />").as("Communications of the ACM")
      end

    end
    
    describe 'Radiant pages' do
      it "should render the homepage title" do
        pages(:home).should render("<r:cacm_page_title />").as("Communications of the ACM")
      end

      it "should render a browse-by-subject title" do
        pages(:artificial_intelligence).should render("<r:cacm_page_title />").as("Artificial Intelligence | Browse by Subject | Communications of the ACM")
      end
      
      it "should render a random radiant page" do
        pages(:widget_page).should render("<r:cacm_page_title />").as("widget page | Communications of the ACM")
      end

    end
  end

  describe 'if_part_has_content' do
    before do
      @part = PagePart.new(:name => 'empty')
      @page = pages(:home)
      @page.stub!(:part).and_return(@part)
    end

    it "should not expand if part is empty" do
      @page.should render('<r:if_part_has_content part="empty">hi</r:if_part_has_content>').as('')
    end

    it "should expand if part has content" do
      @part.content = 'content'
      @page.should render('<r:if_part_has_content part="empty">hi</r:if_part_has_content>').as('hi')
    end
  end

  describe "unless_part_has_content" do
    before do
      @part = PagePart.new(:name => 'empty')
      @page = pages(:home)
      @page.stub!(:part).and_return(@part)
    end

    it "should expand if part is empty" do
      @page.should render('<r:unless_part_has_content part="empty">hi</r:unless_part_has_content>').as('hi')
    end

    it "should not expand if part has content" do
      @part.content = 'content'
      @page.should render('<r:unless_part_has_content part="empty">hi</r:unless_part_has_content>').as('')
    end
  end
end