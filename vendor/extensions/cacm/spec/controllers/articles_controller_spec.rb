require File.dirname(__FILE__) + '/../spec_helper'

describe ArticlesController do
  scenario :subjects, :cacm_articles
  
  before do
    @member = Oracle::Session.new
    controller.stub!(:current_member).and_return(@member)
  end
  
  describe "hit tracking" do
    before do
      controller.instance_variable_set(:@vertical, issues(:december))
      controller.instance_variable_set(:@article, articles(:cacm_article))
      @member.stub!(:can_access?).and_return(true)
    end
  
    it "should track a hit" do
      article = articles(:cacm_article)
      get :fulltext, :article => article.id
      article.hits.size.should_not be_blank
    end
  end
  
  describe "#index" do
    before do
      @subject = subjects(:entertainment)
      controller.instance_variable_set(:@vertical, @subject)
      @article = articles(:cacm_article)
      controller.instance_variable_set(:@article, @article)
      Article.stub!(:find).and_return(@article)
    end
    
    it "should redirect to fulltext if exists and member is authorized" do
      @member.stub!(:can_access?).and_return(true)
      get :index, :article => 999
      response.should redirect_to(:action => 'fulltext')
    end

    it "should redirect to abstract if no fulltext" do
      @article.full_text = ''
      get :index, :article => 999
      response.should redirect_to(:action => 'abstract')
    end
    
    it "should redirect to abstract if unauthorized" do
      stub = stub_everything(:source_stub)
      stub.stub!(:is_open?).and_return(false)
      @article.stub!(:source).and_return(stub)
      @current_member.stub!(:can_access?).and_return(false)
      get :index, :article => 999
      response.should redirect_to(:action => 'abstract')
    end

    it "should redirect allowed crawelrs to fulltext if available" do
      request.remote_addr = CACM::CRAWLER_IPS.first
      get :index, :article => 999
      response.should redirect_to(:action => 'fulltext')
    end
  end

  describe "#fulltext" do
    before do
      @subject = subjects(:entertainment)
      controller.instance_variable_set(:@vertical, @subject)
      @article = articles(:cacm_article)
      controller.instance_variable_set(:@article, @article)
      @article.full_text = 'LOREM IPSUM'
      Article.stub!(:find).and_return(@article)
    end
    
    describe "when authorized" do
      before do
        @member.stub!(:can_access?).and_return(true)
        controller.stub!(:format_accessible?).and_return(true)
      end

      it "should track a hit if article" do
        @article.should_receive(:track).with(hash_including(:format => :html, :request => request))
        get :fulltext, :article => 999
      end
      
      it "should render" do
        @controller.stub!(:track_hit).and_return(true)
        get :fulltext, :article => 1
        response.should render_template('articles/fulltext')
      end
    end
    
    describe "when unauthorized" do
      before do
        @member.stub!(:can_access?).and_return(false)
      end
      
      it "should not track a hit if article is unavailable" do
        @article.should_not_receive(:track)
        get :fulltext, :article => 999
      end
      
      it "should render barrier" do
        get :fulltext, :article => 1
        response.should render_template('barrier.html.haml')
      end
    end

    describe "stale IP-based session" do
      before do
        @member.stub!(:inst?).and_return(true)
        @member.stub!(:indv?).and_return(false)
        @member.stub!(:fresh?).and_return(false)
        @member.stub!(:authenticate_ip).and_return(true)
        @member.stub!(:can_access?).and_return(true)
        @controller.stub!(:track_hit).and_return(true)
      end

      it "should show the article" do
        get :fulltext, :article => '500'
        response.should render_template('articles/fulltext')
      end

      it "should refresh the session" do
        @member.should_receive(:authenticate_ip).and_return(true)
        get :fulltext, :article => '500'
      end
    end

    describe "stale login-based session" do
      before do
        @member.stub!(:inst?).and_return(true)
        @member.stub!(:indv?).and_return(true)
        @member.stub!(:fresh?).and_return(false)
        @member.stub!(:refresh!).and_return(true)
        @member.stub!(:can_access?).and_return(true)
        @controller.stub!(:track_hit).and_return(true)
      end

      it "should show the article" do
        get :fulltext, :article => '500'
        response.should render_template('articles/fulltext')
      end

      it "should refresh the session" do
        @member.should_receive(:refresh!).and_return(true)
        get :fulltext, :article => '500'
      end
    end
  end
  
  describe "#pdf" do
    before do
      @subject = subjects(:entertainment)
      controller.instance_variable_set(:@vertical, @subject)
      controller.stub!(:spec_mocks_mock_url).and_return('http://test.host/')
      @article = articles(:cacm_article)
      @article.full_text = 'LOREM IPSUM'
      controller.instance_variable_set(:@article, @article)
      @source = stub_everything('oracle_article')
      @article.stub!(:source).and_return(@source)
    end
    
    describe "when article is available" do
      before do
        @member.stub!(:can_access?).and_return(true)
        controller.stub!(:format_accessible?).and_return(true)
      end
      
      it "should redirect GSA to proxy URL" do
        @source.should_receive(:crawl_url).and_return('/crawl/url')
        request.remote_addr = CACM::CRAWLER_IPS.first
        controller.should_receive(:redirect_to).with(/crawl\/url/, :status => 302)
        get :pdf, :article => 1
      end
      
      it "should redirect users to delivery.acm URL" do
        @source.should_receive(:url).and_return('/redirect/url')
        controller.should_receive(:redirect_to).with(/redirect\/url/, :status => 302)
        get :pdf, :article => 1
      end
      
      it "should raise a routing error if PDF is requested but no PDF is available" do
        @article.stub!(:has_pdf?).and_return(false)
        lambda {get :pdf, :article => 1}.should raise_error(ActionController::RoutingError)
      end
      
      it "should not track hit" do
        @article.should_not_receive(:track).with(:request => request)
        get :pdf, :article => 1
      end
    end
    
    describe "when article is unavailable" do
      before do
        @member.stub!(:can_access?).and_return(false)
      end
      
      it "should render barrier" do
        get :pdf, :article => 1
        response.should render_template('barrier.html.haml')
      end
      
      it "should not track hit" do
        @article.should_not_receive(:track).with(:request => request)
        get :pdf, :article => 1
      end
    end
  end
  
  describe "#comments" do
    before do
      @subject = subjects(:entertainment)
      controller.instance_variable_set(:@vertical, @subject)
      @comments = stub_everything(:comments)
      @article = mock_model(Article, :track => true, :comments => @comments, :user_comments? => true)
      Article.stub!(:find).and_return(@article)
      controller.instance_variable_set(:@article, @article)
    end

    it "should load comments" do
      @comments.should_receive(:paginate)
      get :comments, :article => '123'
    end
  end

  describe "#syndicate" do
    before do
      @subject = subjects(:entertainment)
      controller.instance_variable_set(:@vertical, @subject)
    end

    it "should render an rss feed" do
      get :syndicate
      response.should render_template('articles/syndicate')
    end

    it "should not run any auth. filters" do
      controller.should_not_receive(:authenticate_by_ip)
      get :syndicate
    end
  end
  
  describe "#format_accessible" do
    it "should skip method when user is a local crawler" do
      request = mock(:request, :remote_ip => CACM::CRAWLER_IPS.first, :request_uri => 'http://test.host/articles/123')
      controller.stub!(:request).and_return(request)
      controller.should_not_receive(:session_valid?)
      controller.send(:format_accessible?).should be_true
    end
    
    it "should return true if article is not a DL article" do
      controller.stub!(:request).and_return(request)
      @article = mock_model(Article, :track => true, :comments => @comments, :user_comments? => true)
      Article.stub!(:find).and_return(@article)
      controller.should_not_receive(:session_valid?)
      controller.send(:format_accessible?).should be_true
    end
    
    it "should return false if user agent is an external crawler" do
      request = mock(:request, :user_agent => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', :remote_ip => '127.0.0.1', :request_uri => 'http://test.host/articles/123')
      controller.stub!(:request).and_return(request)
      controller.should_receive(:render).with(hash_including(:action => 'barrier.html.haml'))
      controller.should_not_receive(:session_valid?)
      controller.send(:format_accessible?).should be_false
    end
  end

end