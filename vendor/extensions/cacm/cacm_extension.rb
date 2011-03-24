require_dependency 'application'
require 'curb'
require 'global_scope'
require 'has_finder'
require 'recaptcha'

class CacmExtension < Radiant::Extension
  version "1.0"
  description "CACM Extension"
  url "http://cacm.acm.org/"

  # log file to keep track of errors encountered in feed ingestion
  INGESTION_LOGGER = ActiveSupport::BufferedLogger.new("#{RAILS_ROOT}/log/ingestion.log")
  INGESTION_LOGGER.auto_flushing = false
  EMAIL_LOGGER = ActiveSupport::BufferedLogger.new("#{RAILS_ROOT}/log/email.log")
  EMAIL_LOGGER.auto_flushing = false

  ActiveRecord::Base.send(:include, AssetManager::BelongsToAsset)
  
  define_routes do |map|
    # Set account/session protocol if needed
    protocol = %w(test development development_cached).include?(RAILS_ENV) ? 'http' : 'https'
    
    # == == Admin Routing == ==

    # Admin Picker Routing
    map.associated_widgets 'admin/picker/associated_widgets', :controller => 'cacm_admin/widget_picker', :action => 'associated_widgets'
    map.associated_articles 'admin/picker/associated_articles', :controller => 'cacm_admin/article_picker', :action => 'associated_articles'

    # Admin Article Previewing
    map.preview_admin_article 'admin/articles/preview', :controller => 'cacm_admin/articles_preview', :action => 'create', :conditions => { :method => :put }

    # Duplication of routing for the blogger role. Must be above cacm_admin otherwise 
    # routing precidence will make this not work
    map.with_options(:path_prefix => "admin/blog", :controller => 'cacm_admin/articles', :feed_id => CACM::BLOG_FEED_ID) do |blog|
      blog.default_blog '/', :action => "index"
      blog.new_article '/new', :action => "new"
      blog.create '/create', :action => "create"
      blog.edit '/:id/edit', :action => "edit"
      blog.update '/:id', :action => "update" , :conditions => { :method => :put }
    end
    
    # Duplication of routing for the blogger role for comments. Must be above cacm_admin otherwise 
    # routing precidence will make this not work
    map.with_options(:path_prefix => "admin/comments_blog", :controller => 'cacm_admin/comments', :feed_id => CACM::BLOG_FEED_ID) do |blog_comments|
      blog_comments.index "/", :action => "index"
      blog_comments.approve "/approve/:id", :action => "approve"
      blog_comments.reject "/reject/:id", :action => "reject"
      blog_comments.edit '/:id/edit', :action => "edit"
      blog_comments.update '/:id', :action => "update" , :conditions => { :method => :put }
    end
       
    map.new_fetch_admin_issue 'admin/issues/fetch/', :controller => "cacm_admin/issues", :action => "new", :conditions => { :method => :get }
    map.fetch_admin_issue 'admin/issues/fetch/', :controller => "cacm_admin/issues", :action => "fetch", :conditions => { :method => :post }
    
    # Admin Resource Routing
    map.namespace :cacm_admin do |admin|
      admin.with_options(:path_prefix => "/admin", :name_prefix => "admin_" ) do |a|
        a.resources :articles, :member => { :refresh => :post, :reject => :put }
        a.resources :feeds
        a.resources :issues, :member => { :publish => :get, :unpublish => :get, :fix => :get }
        a.resources :widgets, :member => { :safeedit => :get }
      end
    end

    # Admin Comment Moderation
    map.with_options(:path_prefix => "admin/comments", :controller => "cacm_admin/comments") do |comments|
      comments.moderate_comments '/', :action => 'index'
      comments.approve_comment '/approve/:id', :action => 'approve'
      comments.reject_comment '/reject/:id',  :action => 'reject'
      comments.edit '/:id/edit', :action => "edit"
      comments.update '/:id', :action => "update" , :conditions => { :method => :put }
    end

    # DL Ingestion
    map.connect 'admin/ingest', :controller => 'cacm_admin/ingest', :action => 'new', :conditions => { :method => :get }
    map.connect 'admin/ingest', :controller => 'cacm_admin/ingest', :action => 'create', :conditions => { :method => :post }

    # Admin Ingestion
    map.ingest 'admin/feed/:id/ingest', :controller => 'cacm_admin/feeds', :action => 'ingest'

   
    
    

    # == == Front End Routing == ==

    # Magazines Archive
    map.with_options :controller => 'archives' do |archives|
      archives.magazine_issue '/magazines/:year/:month',  :action => 'toc',  :year => /([0-9]){4}/, :month => /([0-9]){1,2}/
      archives.magazines_by_year '/magazines/:year',      :action => 'year', :year => /([0-9]){4}/
      archives.magazines '/magazines',                    :action => 'index'
    end

    # Article Routing by Magazine YEAR / MONTH
    map.with_options :controller => 'magazines' do |magazines|
      magazines.connect '/magazine.rss', :action => 'syndicate', :format => 'rss'
      magazines.connect '/magazines/:year/:month/:article/comments', :controller => 'comments', :action => 'create', :conditions => { :method => :post } ,:year => /([0-9]){4}/, :month => /([0-9]){1,2}/
      magazines.connect '/magazines/:year/:month/:article/supplements/:id', :action => 'supplements'
      magazines.connect '/magazines/:year/:month/:article/:action',  :year => /([0-9]){4}/, :month => /([0-9]){1,2}/
    end

    # subscriptions handling
    map.with_options :controller => 'subscriptions' do |subscriptions|
      subscriptions.update_subscription '/alerts-and-feeds/email-alerts', :action => 'update', :conditions => { :method => :put }
      subscriptions.subscription '/alerts-and-feeds/email-alerts', :action => 'edit'
    end

    # Article Routing by SECTION
    if ActiveRecord::Base.connection.tables.include?("sections")
      map.with_options :controller => 'sections' do |sections|

        sections.with_options :section => Section.find_or_create_by_name('News').id do |news|
          news.connect '/news.rss', :action => 'syndicate', :format => 'rss'
          news.connect '/news/:article/comments', :controller => 'comments', :action => 'create', :conditions => { :method => :post }
          news.connect '/news/:article/supplements/:id', :action => 'supplements'
          news.connect '/news/:article/:action', :article => /\d+(\-[^\/]+)?/ # this is the regexp needed for matching article slugs.
        end

        sections.with_options :section => Section.find_or_create_by_name('Careers').id do |careers|
          careers.connect '/careers.rss', :action => 'syndicate', :format => 'rss'
          careers.connect '/careers/:article/comments', :controller => 'comments', :action => 'create', :conditions => { :method => :post }
          careers.connect '/careers/:article/supplements/:id', :action => 'supplements'
          careers.connect '/careers/:article/:action'
        end

        sections.with_options :section => Section.find_or_create_by_name('Opinion').id do |opinion|
          opinion.connect '/opinion.rss', :action => 'syndicate', :format => 'rss'
          opinion.connect '/opinion/articles/:article/comments', :controller => 'comments', :action => 'create', :conditions => { :method => :post }
          opinion.connect '/opinion/articles/:article/supplements/:id', :action => 'supplements'
          opinion.connect '/opinion/articles/:article/:action'
        end

        sections.with_options :section => Section.find_or_create_by_name('Interviews').id do |interviews|
          interviews.connect '/opinion/interviews/:article/comments', :controller => 'comments', :action => 'create', :conditions => { :method => :post }
          interviews.connect '/opinion/interviews/:article/supplements/:id', :action => 'supplements'
          interviews.connect '/opinion/interviews/:article/:action'
        end

        sections.with_options :section => Section.find_or_create_by_name('Blog CACM').id do |comm|
          comm.connect '/blogs/blog-cacm.rss', :action => 'syndicate', :format => 'rss'
          comm.connect '/blogs/blog-cacm/:article/comments', :controller => 'comments', :action => 'create', :conditions => { :method => :post }
          comm.connect '/blogs/blog-cacm/:article/supplements/:id', :action => 'supplements'
          comm.connect '/blogs/blog-cacm/:article/:action'
        end
      end
    end

    # Article Routing by SUBJECT
    if ActiveRecord::Base.connection.tables.include?("subjects")
      Subject.find(:all).each do |sub|
        map.with_options :controller => 'subjects', :subject => sub.id do |subject|
          subject.connect "/browse-by-subject/#{sub.to_param}.rss", :action => 'syndicate', :format => 'rss'
          subject.connect "/browse-by-subject/#{sub.to_param}/:article/comments", :controller => 'comments', :action => 'create', :conditions => { :method => :post }
          subject.connect "/browse-by-subject/#{sub.to_param}/:article/supplements/:id", :action => 'supplements'
          subject.connect "/browse-by-subject/#{sub.to_param}/:article/:action"
        end
      end
    end

    # Session Routing
    map.with_options(:controller => 'session') do |session|
      session.connect '/login', :action => 'create', :protocol => protocol , :conditions => { :method => :post }
      session.member_login '/login', :action => 'new', :protocol => protocol
      session.member_logout '/logout', :action => 'destroy'
    end

    # Registration Process / User Account Routing
    map.with_options(:controller => 'accounts', :path_prefix => "/accounts") do |account|
      account.new_account '/new', :action => 'new'
      account.create_account '/create', :action => 'create', :protocol => protocol, :conditions => { :method => :post }
      account.verify_account '/verify', :action => 'verify', :protocol => protocol, :conditions => { :method => :get  }
      account.complete_account '/complete', :action => 'complete', :protocol => protocol
      
      account.verify_membership '/verify_membership', :action => 'verify_membership'

      account.forgot_password '/forgot-password', :action => 'forgot', :conditions => { :method => :get }
      account.find_question '/question', :action => 'question', :protocol => protocol, :conditions => { :method => :post }
      account.answer_question '/edit', :action => 'edit', :protocol => protocol, :conditions => { :method => :post }
      account.update_account '/update', :action => 'update', :protocol => protocol, :conditions => { :method => :post }
    end

    # Search Routing
    map.connect '/search', :controller => 'search', :action => 'search'

  end
  
  def activate
    # customize the Radiant admin page titles a bit
    Radiant::Config['admin.title'] = "CACM Website Manager"
    Radiant::Config['admin.subtitle'] = "Powered by Radiant CMS"

    # email settings for app (overridable in local_config.rb)
    ActionMailer::Base.delivery_method = :smtp
    ActionMailer::Base.smtp_settings = {
      :address => 'acm26-2.acm.org',
      :domain => 'cacm.acm.org',
      :port => 25
    }
    ActionMailer::Base.mock_address = 'cacm-dev@digitalpulp.com'
    ActionMailer::Base.exception_address = ExceptionNotifier.email_to = ExceptionNotifier.email_from = 'cacm-errors@digitalpulp.com'
    ActionMailer::Base.perform_deliveries = :mock # do not modify -- override in local_config.rb

    # give the entire front-end some universal helpers
    ApplicationController.class_eval{ helper :cacm }
    ApplicationController.class_eval{ helper CACM::SectionsPathHelper }

    # include CACM-specifc string methods
    String.send(:include, CACM::StringExtensions)

    # extend acts_as_commentable with CACM customizations
    Comment.send(:include, CACM::CommentExtensions)

    # make the truncate_html helper everywhere
    ActionView::Base.send(:include, TextHelper)

    # allow Widgets to use the TagHelper
    CACM::WidgetTags.send(:include, ActionView::Helpers::TagHelper)

    # On save ensure FCK Content is Cleaned Up
    Snippet.send(:include, CACM::FCKExtensions)
    PagePart.send(:include, CACM::FCKExtensions)

    # customize the Radiant admin for CACM
    ApplicationController.send(:include, CACM::ApplicationExtensions) 

    # navigational niceties
    Admin::PageController.send(:include, CACM::PageControllerExtensions)
    
    # override app's page helper with our quieter page editing edition
    Admin::PageHelper.send(:include, CACM::PageHelper)

    # activate sessions in SiteController
    SiteController.send(:include, CACM::SiteExtensions)

    # kill CACM session variables when logging out of Radiant
    Admin::WelcomeController.send(:include, CACM::WelcomeControllerExtensions)

    # allow Radiant pages to use custom radius and widget tags as well as 
    Page.send(:include, CACM::RadiusTags, CACM::WidgetTags, CACM::PageExtensions)

    # follow-redirect and HEAD methods
    Net::HTTP.send(:include, CACM::NetHttpExtensions)

    # override the app's settings with the local environment's unique requirements via local_config.rb
    #CACM.send(:include, LOCAL_CONFIG)

    # remove default Radiant tabs to define them with roles added
    admin.tabs.remove "Pages"
    admin.tabs.remove "Assets"
    admin.tabs.remove "Roles" # in CMS Settings
    admin.tabs.remove "CMS Settings" # re-added with roles

    # configure the tabs in the Radiant admin UI
    admin.tabs.add "Pages",       "/admin/pages",                               :visibility => CACM::FULL_ACCESS_ROLES
    admin.tabs.add "Assets",      "/admin/assets",                              :visibility => CACM::FULL_ACCESS_ROLES
    admin.tabs.add "CAE",         "/admin/articles",      :after => 'Pages',    :visibility => CACM::FULL_ACCESS_ROLES
    admin.tabs.add "Issues",      "/admin/issues",        :after => 'Assets',   :visibility => CACM::FULL_ACCESS_ROLES
    admin.tabs.add "Widgets",     "/admin/widgets",       :after => 'Issues',   :visibility => CACM::FULL_ACCESS_ROLES
    admin.tabs.add "Comments",    "/admin/comments",      :after => 'Widgets',  :visibility => CACM::FULL_ACCESS_ROLES
    admin.tabs.add "CMS Settings", "/admin/cms_settings", :after => "Comments", :visibility => CACM::ADMIN_ACCESS_ROLES

    # blogger role tabs
    Role.register(:blogger)
    admin.tabs.add "Blog Articles" , "admin/blog",          :visibility => [:blogger]
    admin.tabs.add "Blog Comments" , "admin/comments_blog", :visibility => [:blogger]
    
    
    # Boot some classes according to sphinx vs. oracle interactions
    require_dependency 'oracle'
    Dir.glob(File.join(self.class.root, %w(app models oracle), '*.rb')).each { |f| require_dependency f }
    Dir.glob(File.join(self.class.root, %w(app models), '*article.rb')).each { |f| require_dependency f }
    
    # Attach Observers
    ArticleSweeper.instance
    CommentSweeper.instance

    #Recaptcha
    Recaptcha.configure do |config|
      config.public_key = CACM::RECAPTCHA_PUBLIC_KEY
      config.private_key = CACM::RECAPTCHA_PRIVATE_KEY
    end
  end
  
  def deactivate
  end
  
end
