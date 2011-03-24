module CACM
  module WidgetTags
    include Radiant::Taggable
    include CACM::SectionsPathHelper
    include CacmHelper
    
    # Note on comments: description tags are used specifically for widget attrs
    # in this file, so exercise caution when editing widget desc's. They need
    # to be able to be converted into yaml.
    
    class TagError < StandardTags::TagError; end
    
    # property declarations on widgets did not get along with cache tags.
    # this lets us wrap both a cache and a widget in a dummy tag that gets
    # the placeholder image properties.
    tag 'placeholder' do |tag|
      tag.expand
    end

    # Widgets
    # The r:widgets tag is used on content types that have pickable widgets
    # stored in a page part. This parses the widget IDs (comma-separated)
    # and renders each one, concatenating the output of the snippet/widget
    # rendering in order.
    tag 'widgets' do |tag|
      if name = tag.attr['part']
        part = tag.locals.page.part(tag.attr['part'])
        unless part; raise TagError.new("`#{tag.attr['part']}` part does not exist!"); end

        tag.locals.widgets = part.content.split(',') rescue []

        returning [] do |result|
          tag.locals.widgets.each do |widget_and_attrs|
            tag.locals.widget_attrs = widget_and_attrs.split("|")[1]
            widget = Widget.find_by_id(widget_and_attrs.split("|")[0])
            result << tag.globals.page.render_snippet(widget) if widget
          end
        end
      else
        raise TagError.new("`widgets` tag must contain `part` attribute")
      end
    end

    # Widget
    # This calls the same render_snippet magic that renders the widget, but
    # this only takes a single widget (identified by name) and finds that.
    # This is used to hardcode widgets within markup with the r:widget pattern.
    tag 'widget' do |tag|
      if name = tag.attr['name']
        if widget = Widget.find_by_name(name)
          tag.locals.yield = tag.expand if tag.double?
          tag.globals.page.render_snippet(widget)
        else
          raise TagError.new('widget not found')
        end
      else
        raise TagError.new("`widget' tag must contain `name' attribute")
      end
    end

    # Dynamic Tag
    # dynamic tag is used to insert values into an html tag attribute, when
    # the inserted value is determined by a radius tag. This works fine normally,
    # but not if the tag was wrapping another radius tag. This will dodge the
    # situation by piping the entire thing through radius tag parsing.
    # For example, if a widget has a link that has the attribute href, which is
    # determined by a r:link radius tag, on the widget markup:
    # r:dynamic_tag, :tag => 'a', :href => 'r:link'
    #   %r:link_text
    
    tag 'dynamic_tag' do |tag|
      raise TagError.new("`dynamic_tag' requires a `tag' attribute") unless tag.attr["tag"]

      attrs = tag.attr.dup
      attrs.delete("tag")

      rendered_attrs = returning Hash.new do |member|
        attrs.each_pair do |k,v|
          if v[0..1].eql?("r:")
            member[k] = tag.render(v[2..-1])
          else
            member[k] = v
          end
        end
      end
      
      # this avoids the situation where a dynamic image tag is relying
      # on a radius tag for the image's source but the image may not even
      # exist, which would break the dynamic tag. -amlw 1/16/09
      unless tag.attr["tag"].eql?("img") && rendered_attrs["src"].blank?
        content_tag tag.attr["tag"], tag.expand, rendered_attrs
      end
      
    end

    # THESE ARE DOCUMENTED EXAMPLE RADIUS TAG DEFINITIONS FOR CACM DEVS
    # UNCOMMENT THIS LOCALLY AND CREATE A WIDGET WITH THE FOLLOWING BODY
    # TO SEE IT IN ACTION
    # 
    # After you save any attributes you specify will be saved on the markup (it will be modified)
    # to see the modification visit /admin/widgets/{ID}/safeedit or click the safe edit link
    # 
    # <r:article_subjects>
    #   <b>This article has the following subjects:</b>
    #   <br />
    #   <ul>
    #     <r:each>
    #       <li> <r:name /> </li>
    #     </r:each>
    #   </ul>
    # </r:article_subjects>
    # 
    # desc %{
    #   tag: article_subjects
    #   description: Article Subjects Tag for that Widget
    #   usage: <r:article_subjects><r:each>...</r:each></r:article_subjects>
    #   attributes: 
    #     some_text:
    #       legend: This is a Text Field
    #       input: text
    #     preferred_fruit:
    #       legend: This is a Radio Select
    #       input: radio
    #       choices:
    #         banana: Bananas
    #         apple: Apples
    #         orange: Oranges
    #     some_asset:
    #       legend: Pick an Asset
    #       input: asset_picker
    # }
    # tag "article_subjects" do |tag|
    #   # article_from_url and subject_from_url are convenience methods DP has added
    #   # that return the subject or article by URL introspection.
    #   # The methods are visible in cacm_helper.rb
    #   if article = article_from_url
    #     # You can add anything into tag.locals so we're just defining, on the fly 
    #     # tag.locals.article_subjects which will persist for tags nested within it
    #     tag.locals.article_subjects = article.subjects
    #     tag.expand if tag.locals.article_subjects.any?
    #   end
    # end
    # 
    # tag "article_subjects:each" do |tag|
    #   returning [] do |result|
    #     tag.locals.article_subjects.each do |subject|
    #       tag.locals.article_subject = subject
    #       result << tag.expand
    #     end
    #   end
    # end
    # 
    # tag "article_subjects:each:name" do |tag|
    #   # tag.locals.article_subject is a Subject object, so we can call name on it directly, 
    #   # just as we could call id, or created_at, or any attribute on any object here.
    #   tag.locals.article_subject.name
    # end

    # Top Articles
    # This tag finds the 5 (or a limit, if specified separately) articles with
    # the most tracked hits. We then collect the title and link in a hash and
    # write out two radius tags to output each value in a list on the top 5 widget.
    tag 'top_articles' do |tag|
      tag.locals.articles_limit = tag.attr['limit']||5
      tag.locals.articles = Article.find_by_sql ["SELECT trackable_id, count(*) AS count FROM `hits` GROUP BY trackable_id ORDER BY count DESC LIMIT ?",tag.locals.articles_limit]
      tag.expand unless tag.locals.articles.blank?
    end
    tag 'top_articles:each' do |tag|
      returning [] do |result|
        tag.locals.articles.each do |article|
          top_article = Article.find(article.trackable_id)
          tag.locals.article = {} 
          tag.locals.article[:title] = top_article.full_title
          tag.locals.article[:link] = contextual_article_path(top_article,request.path)
          result << tag.expand
        end
      end
    end
    [:title,:link].each do |attr|
      tag "top_articles:each:#{attr}" do |tag|
        tag.locals.article[attr]
      end
    end

    # Featured Article
    # This widget is picked and placed on the homepage and listing pages. If
    # things are set up properly, tag.locals.widget_attrs is the ID of an
    # article that was picked through the featured article picker. This tag
    # pulls in all the various pieces of data for the featured article output
    # and then iterates over each attribute for direct output in the widget
    # template.
    
    tag 'featured_article' do |tag|
      if tag.locals.widget_attrs
        cache :widget => 'featured_article', :id => tag.locals.widget_attrs do
          
          featured_article = Article.find_by_id(tag.locals.widget_attrs)
          unless featured_article.nil?
          
            tag.locals.featured_article = {}
            tag.locals.featured_article[:title] = CGI.escapeHTML(featured_article.full_title)
            tag.locals.featured_article[:date] = featured_article.date.strftime("%m.%d.%Y")
            tag.locals.featured_article[:link] = contextual_article_path(featured_article,request.path)
          
            # Does the article have a CACM-based section assignment?
            tag.locals.featured_article[:slugline] = featured_article.sections.first.name rescue nil
            tag.locals.featured_article[:slugline] = tag.locals.featured_article[:slugline].nil? ? featured_article.source.section.title : tag.locals.featured_article[:slugline] rescue "Communications"
            tag.locals.featured_article[:slugline] = "blog@CACM" if tag.locals.featured_article[:slugline].eql?("Blog CACM") # replace "Blog CACM" with "blog@CACM"
          
            # Find the section URL or the magazine path
            has_a_section = featured_article.sections.length >= 1 ? featured_article.sections.first : false
            if has_a_section
              title = has_a_section.name.eql?("Blog CACM") ? "blog@CACM" : has_a_section.name
              tag.locals.featured_article[:slug_url] = tag_wrapper('a', "View More #{title}", :href => has_a_section.to_param)
            else
              tag.locals.featured_article[:slug_url] = tag_wrapper('a', "View The Issue", :href => magazine_issue_path(featured_article.date.year, featured_article.date.month))
            end
          
            # Try to find a thumbnail, if it exists
            if featured_article.image_id 
              if File.exist?(RAILS_ROOT + "/public" + featured_article.image.public_filename(:small).split("?").first)
                tag.locals.featured_article[:thumbnail] = CGI.escapeHTML(featured_article.image.public_filename(:small))
              elsif File.exist?(RAILS_ROOT + "/public" + featured_article.image.public_filename(:small_square).split("?").first)
                tag.locals.featured_article[:thumbnail] = CGI.escapeHTML(featured_article.image.public_filename(:small_square))
              end
            else
              tag.locals.featured_article[:thumbnail] = ""
            end
          
            # Try to drill down to the most specific byline possible
            if featured_article.is_dl_article?
              if featured_article.class.to_s != "CacmArticle" && featured_article.class.to_s != "DLArticle"
                tag.locals.featured_article[:by_line] = featured_article.source_human_name.slice(0..4)
              elsif featured_article.class.to_s == "DLArticle"
                tag.locals.featured_article[:by_line] = "Communications of the ACM"
              else
                tag.locals.featured_article[:by_line] = featured_article.feed.name
              end
            else
              tag.locals.featured_article[:by_line] = featured_article.feed.name
            end
          
            if featured_article.short_description && !featured_article.short_description.empty?
              tag.locals.featured_article[:short_description] = truncate_html(featured_article.short_description, 250)
            else
              tag.locals.featured_article[:short_description] = ""
            end
          
            tag.expand
          end
          
        end
      end
    end
    [:slugline,:slug_url,:date,:thumbnail,:title,:link,:by_line,:short_description].each do |attr|
      tag "featured_article:#{attr}" do |tag|
        tag.locals.featured_article[attr]
      end
    end

    # Related Article Content
    # This tag wraps the related_resources widget, which uses the three
    # radius tags listed below. Those radius tags MIGHT not reveal any content,
    # meaning that the widget would be a header and three empty content areas.
    # To avoid the situation where a header has no content, we will first expand
    # the tag, and then verify that at least one of the headers was output by
    # the other three tags.
    
    tag 'related_article_content' do |tag|
      html = tag.expand
      if html.match(/(<h4>Conferences:<\/h4>)|(<h4>Books:<\/h4>)|(<h4>Courses:<\/h4>)/) 
        html
      else
        ""
      end
    end
    
    # Conference Resource, Book Resource, Course Resource
    # This iterates over the three potential types of resources "conferences"
    # "book" and "course" and generates a radius tag of XXX_resouce for each
    # type of resource. Each tag uses the Feed types (e.g. book_feeds) to 
    # find specific results for each section.
    
    [:conference, :book, :course].each do |sym|
      tag "#{sym}_resource" do |tag|

        if article = article_from_url
          query = {:conditions => ['state = (?) AND feed_id IN (?) AND subjects.id IN (?)','approved',Feed.send("#{sym}_feeds"),article.subjects], :include => :subjects, :order => 'RAND()', :limit => 1}
        elsif subject = subject_from_url
          query = {:conditions => ['state = (?) and feed_id IN (?) and subjects.id = (?)', 'approved',Feed.send("#{sym}_feeds"),subject], :include => :subjects, :order => "RAND()", :limit => 1}
        else
          query = {:conditions => ['state = (?) AND feed_id IN (?)','approved',Feed.send("#{sym}_feeds")], :order => 'RAND()', :limit => 1}
        end

        if :conference == sym
          query[:conditions].first << ' AND date >= ?'
          query[:conditions] << Date.today.to_time
        end

        resource = Article.find :first, query

        if resource
          tag.locals.resource = {}
          tag.locals.resource[:link]   = resource.link
          tag.locals.resource[:title]  = resource.full_title

          case sym
          when :conference
            tag.locals.resource[:teaser] = resource.short_description.to_teaser(10)
          when :book
            tag.locals.resource[:teaser] = resource.author.to_teaser(10)
          when :course
            tag.locals.resource[:teaser] = resource.short_description.to_teaser(25)
          end

          tag.expand
        end
      end
      [:link,:title,:teaser].each do |attr|
        tag "#{sym}_resource:#{attr}" do |tag|
          tag.locals.resource[attr]
        end
      end
    end

    # From The Blogs
    # This widget has an article picker built into it. The tag itself takes in
    # widget_attrs, which is the list of articles that have been picked by
    # the widget admin. Each article (comma separated) is found and dropped into
    # and array of articles.
    desc %{
      tag: from_the_blogs
      description: Pick Articles 
      usage: <r:from_the_blogs></r:from_the_blogs>
      attributes: 
        article_ids:
          legend: Pick Blog Articles
          input: blog_articles_picker
    }
    tag 'from_the_blogs' do |tag|
      cache 'from_the_blogs' do
        tag.locals.from_the_blogs = []
        tag.attr['article_ids'].split(",").each do |id|
          tag.locals.from_the_blogs << Article.find_by_id(id)
        end
        tag.locals.from_the_blogs.compact!
        tag.expand unless tag.locals.from_the_blogs.empty?
      end
    end
    tag 'from_the_blogs:each' do |tag|
      returning [] do |result|
        tag.locals.from_the_blogs.each do |blog|
          tag.locals.from_the_blog = {}
          tag.locals.from_the_blog[:title] = blog.title
          
          # External blogs should link off-site, instead of 404'ing
          if blog.is_a? RssArticle
            tag.locals.from_the_blog[:url] = blog.link
          else
            tag.locals.from_the_blog[:url] = contextual_article_path(blog, request.path)
          end
          
          tag.locals.from_the_blog[:short_description] = truncate_html(blog.short_description.to_teaser(150), 150, "&hellip;")
          tag.locals.from_the_blog[:author] = (blog.author.nil? || blog.author.blank?) ? "" : "by " + blog.author
          tag.locals.from_the_blog[:date] = blog.date.to_s(:mdy_short)
          comments = blog.comments_count
          if comments.eql?(0)
            tag.locals.from_the_blog[:comments] = "No Comments"
          else
            tag.locals.from_the_blog[:comments] = comments.eql?(1) ? "1 Comment" : "#{comments} Comments"
          end
          result << tag.expand
        end
      end
    end
    [:title,:short_description,:author,:date,:comments,:user_comments,:url].each do |attr|
      tag "from_the_blogs:each:#{attr}" do |tag|
        tag.locals.from_the_blog[attr]
      end
    end
    tag "from_the_blogs:each:if_comments" do |tag|
      tag.expand if tag.locals.from_the_blog[:user_comments]
    end
    
    # Featured Jobs
    # This widget finds articles from the featured job feed (feed_id = 15) that 
    # are from within the last 2 weeks. The article limit is 10, but if we don't 
    # find 10 articles from the featured feed, we fill up the rest of the array
    # with articles from the regular job feed (feed_id = 14).
    desc %{
      tag: featured_jobs
      description: Featured Jobs
      usage: <r:featured_jobs></r:featured_jobs>
      attributes:
        limit:
          legend: How many jobs should be displayed?
          input: select
          range:
            low: 1
            high: 15
    }
    tag 'featured_jobs' do |tag|
      limit = (tag.attr['limit']||10).to_i
      conditions = ['state = (?) AND date >= (?)','approved',2.weeks.ago]
      select = 'id,title,date,state,feed_id,link,short_description'

      # Select up to the limit
      tag.locals.featured_jobs = Article.find_all_by_feed_id(15, :conditions => conditions, :limit => limit, :select => select, :order => "RAND()")

      # If there are less than the limit, fill it up
      if tag.locals.featured_jobs.size < limit
        tag.locals.featured_jobs += Article.find_all_by_feed_id(14, :conditions => conditions, :limit => limit-tag.locals.featured_jobs.size, :select => select, :order => "RAND()")
      end

      tag.expand unless tag.locals.featured_jobs.empty?
    end
    tag 'featured_jobs:each' do |tag|
      returning [] do |result|
        tag.locals.featured_jobs.each do |job|
          tag.locals.featured_job = job
          tag.locals.featured_job_data = {}
          tag.locals.featured_job_data[:link] = CGI.escapeHTML(job.link)
          tag.locals.featured_job_data[:title] = job.title
          tag.locals.featured_job_data[:short_description] = job.short_description
          result << tag.expand
        end
      end.join("\n")
    end
    [:link,:title,:short_description].each do |attr|
      tag "featured_jobs:each:#{attr}" do |tag|
        tag.locals.featured_job_data[attr]
      end
    end
    tag 'featured_jobs:each:check_for_feed_switch' do |tag|
      unless tag.globals.featured_job_feed
        tag.globals.featured_job_feed = tag.locals.featured_jobs.first.feed_id # Set it the first time through
      end
      if tag.globals.featured_job_feed.eql?(15) && tag.locals.featured_job.feed_id.eql?(14) # Switch!
        tag.globals.featured_job_feed = 14
        "</ul><ul id='jobs'><li id='jobs-header'>Additional Job Listings</li>"
      end
    end
    
    # Upcoming Conferences
    # This widget finds 5 articles from the Event feed types and loops over
    # them, finding values and outputting them as per the usual pattern.
    tag 'upcoming_conferences' do |tag|
      if subject = subject_from_url
        tag.locals.upcoming_conferences = Article.find(:all, :order => :date, :limit => 5, :include => :subjects, :conditions => ['state = (?) and feed_id in (?) and subjects.id = (?) and date > (?)', 'approved', Feed.event_feeds.map(&:id), subject, Time.now])
      end
      # only run this if we couldn't find the subject, or there were just no results for the subject-limited query
      tag.locals.upcoming_conferences = Article.find(:all, :conditions => ['state = (?) AND feed_id IN (?) AND date > (?)','approved',Feed.event_feeds.map(&:id),Time.now], :order => :date, :limit => 5) if tag.locals.upcoming_conferences.nil? || tag.locals.upcoming_conferences.empty?
      tag.expand unless tag.locals.upcoming_conferences.empty?
    end
    tag 'upcoming_conferences:each' do |tag|
      returning [] do |result|
        tag.locals.upcoming_conferences.each do |conference|
          tag.locals.conference = {}
          tag.locals.conference[:title] = conference.full_title
          tag.locals.conference[:date] = conference.short_description.to_teaser(10)
          tag.locals.conference[:link] = conference.link
          result << tag.expand
        end
      end
    end
    [:title,:date,:link].each do |attr|
      tag "upcoming_conferences:each:#{attr}" do |tag|
        tag.locals.conference[attr]
      end
    end

    # Featured Book
    # This widget is also powered by the radiant admin who picks an article
    # through the widget admin article picker, which restricts the type of 
    # picked article to ones from the Book feed types. Now we find the article
    # that was picked, collect certain parameters, and output them as per the
    # usual radius pattern.
    desc %{
      tag: featured_book
      description: Featured Book
      usage: <r:featured_book></r:featured_book>
      attributes:
        article_id:
          legend: Please select the book to feature
          input: book_picker
    }
    tag 'featured_book' do |tag|
      cache 'featured_book' do
        tag.locals.featured_book = Article.find_by_id(tag.attr['article_id'])
        if tag.locals.featured_book
          tag.locals.featured_book_data = {}
          tag.locals.featured_book_data[:link] = tag.locals.featured_book.link rescue "/"
          tag.locals.featured_book_data[:title] = tag.locals.featured_book.full_title
          tag.locals.featured_book_data[:author] = "by " + tag.locals.featured_book.author
          tag.locals.featured_book_data[:teaser] = tag.locals.featured_book.short_description
          tag.locals.featured_book_data[:thumbnail] = tag.locals.featured_book.image.public_filename if tag.locals.featured_book.image
          tag.expand
        end
      end
    end
    tag 'featured_book:if_thumbnail' do |tag|
      tag.expand if tag.locals.featured_book.image_id && File.exist?(RAILS_ROOT + "/public" + tag.locals.featured_book.image.public_filename.split("?").first)
    end
    [:link,:title,:author,:teaser,:thumbnail].each do |attr|
      tag "featured_book:#{attr}" do |tag|
        tag.locals.featured_book_data[attr]
      end
    end
    
    # Recent News for Subject
    # This widget is placed on each browse by subject page (or was designed to
    # be). First the widget finds the current subject by trimming the end
    # of the URL and figuring out which subject is == to the end when passed
    # through the to_param method (a reverse lookup). Then it finds recent
    # articles similarly to the latest_news tags, collects them into an array,
    # finds attributes for output while iterating over them, and builds out
    # the output tags.
    tag 'recent_news_for_subject' do |tag|
      subject = Subject.find(:all).find { |s| s.to_param == request.parameters['url'].last } rescue nil
      if subject
        tag.locals.recent_news_for_subject = Article.find(:all, :order => "date DESC", :limit => 10,
                                                          :conditions => ["subjects.id = ? AND feed_id in (?)", subject.id, [Feed.find_by_name("ACM TechNews").id, Feed.find_by_name("ACM News").id, Feed.find_by_name("ACM CareerNews")]],
                                                          :include => :subjects)
        tag.expand unless tag.locals.recent_news_for_subject.empty?
      end
    end
    tag 'recent_news_for_subject:each' do |tag|
      returning [] do |output|
        tag.locals.recent_news_for_subject.each do |news|
          tag.locals.article = {}
          tag.locals.article[:title] = news.full_title
          tag.locals.article[:link] = contextual_article_path(news, request.path)
          tag.locals.article[:date] = news.date.to_s(:mdy_short)
          tag.locals.article[:comments_count] = news.comments_count
          tag.locals.article[:short_description] = truncate_html(news.short_description.to_teaser(150), 150, "&hellip;")
          tag.locals.article[:author] = (news.author.nil? || news.author.blank?) ? "" : "via " + news.author
          tag.locals.article[:comments] = tag_wrapper('a', "Comments", :href => contextual_article_path(news, request.path)+"/comments") + " (#{tag.locals.article[:comments_count]})"
          output << tag.expand
        end
      end.join("\n")
    end
    [:title,:link,:date,:comments,:short_description,:author].each do |attr|
      tag "recent_news_for_subject:each:#{attr}" do |tag|
        tag.locals.article[attr]
      end
    end
    tag "recent_news_for_subject:each:if_comments" do |tag|
      tag.expand unless tag.locals.article[:comments_count].eql?(0)
    end

    # Recent Issues
    # This finds the 3 latest magazine issues for output in the main navigation.
    # The issues must be approved. Output is performed as per the usual patterns.
    tag 'recent_issues' do |tag|
      cache 'recent_issues' do
        tag.locals.recent_issues = Issue.find(:all, :conditions => ['state = "approved"'], :order => 'pub_date desc', :limit => 3) rescue nil
        tag.expand unless tag.locals.recent_issues.empty?
      end
    end
    tag 'recent_issues:each' do |tag|
      returning [] do |result|
        tag.locals.recent_issues.each do |issue|
          if issue.source
            tag.locals.recent_issue = {}
            tag.locals.recent_issue[:link] = magazine_issue_path(issue.source.pub_date.year,issue.source.pub_date.month)
            tag.locals.recent_issue[:cover] = issue.source.cover_url
            tag.locals.recent_issue[:publication_date] = issue.source.pub_date.strftime('%B %Y')
            tag.locals.recent_issue[:title] = issue.source.title
            result << tag.expand
          end
        end
      end
    end
    [:link,:cover,:publication_date,:title].each do |attr|
      tag "recent_issues:each:#{attr}" do |tag|
        tag.locals.recent_issue[attr]
      end
    end
    
    # Current Issue
    # This widget tag finds the latest approved issue and collects various
    # attributes into a hash, each of which is outputted directly using a
    # radius tag built into the from the current issue widget.
    # The Selected Articles are 3 articles from the current issue that are 
    # selected by a radiant admin in the Issues admin section.
    tag 'current_issue' do |tag|
      tag.locals.current_issue = Issue.find(:first, :conditions => ['state = "approved"'], :order => 'pub_date desc') rescue nil
      if tag.locals.current_issue
        tag.locals.current_issue_source = {}
        tag.locals.current_issue_source[:toc_link] = magazine_issue_path(tag.locals.current_issue.source.pub_date.year,tag.locals.current_issue.source.pub_date.month)
        tag.locals.current_issue_source[:pub_date] = tag.locals.current_issue.source.pub_date.strftime("%B %Y")
        tag.locals.current_issue_source[:link] = magazine_issue_path(tag.locals.current_issue.source.pub_date.year,tag.locals.current_issue.source.pub_date.month)
        tag.locals.current_issue_source[:cover] = tag.locals.current_issue.source.cover_url
        tag.locals.current_issue_source[:digital_library] = tag.locals.current_issue.source.citation_url
        tag.locals.current_issue_source[:digital_edition] = tag.locals.current_issue.source.full_texts.digital_edition.url rescue "http://portal.acm.org/"
        tag.locals.current_issue_articles = (tag.locals.current_issue.selected_article_ids||"").split(',')
        tag.expand
      end
    end
    [:toc_link,:pub_date,:link,:cover,:digital_library,:digital_edition].each do |attr|
      tag "current_issue:#{attr}" do |tag|
        tag.locals.current_issue_source[attr]
      end
    end
    tag 'current_issue:each' do |tag|
      returning [] do |result|
        tag.locals.current_issue_articles.each do |id|
          article = Article.find(id, :select => ['id, title, oracle_id, class_name'])
          tag.locals.current_issue_article = {}
          tag.locals.current_issue_article[:link] = url_for :controller => 'magazines', :year => tag.locals.current_issue.source.pub_date.year, :month => tag.locals.current_issue.source.pub_date.month, :article => article, :action => 'index'
          tag.locals.current_issue_article[:title] = article.full_title
          result << tag.expand
        end
      end
    end
    [:link,:title].each do |attr|
      tag "current_issue:each:#{attr}" do |tag|
        tag.locals.current_issue_article[attr]
      end
    end
    
    # Latest News
    # This tag finds the 5 most recent articles from the News section and
    # outputs their titles/urls as per the usual pattern.
    tag 'latest_news' do |tag|
      cache 'latest_news' do
        tag.locals.latest_news = Section.find_by_name("News").articles.find(:all, :limit => 5, :conditions => {:state => "approved"})
        tag.expand unless tag.locals.latest_news.empty?
      end
    end
    tag 'latest_news:each' do |tag|
      returning [] do |output|
        tag.locals.latest_news.each do |news|
          tag.locals.news = {}
          tag.locals.news[:title] = CGI.escapeHTML(news.full_title)
          tag.locals.news[:url] = contextual_article_path(news,"/news")
          output << tag.expand
        end
      end
    end
    [:title,:url].each do |attr|
      tag "latest_news:each:#{attr}" do |tag|
        return tag.locals.news[attr]
      end
    end
    
    # Featured Interviews
    # The articles used by the featured interviews widget are picked by a 
    # radiant admin when editing the correlating widget (also called featured
    # interviews). The articles are limited to interview feeds. After we
    # fetch the article IDs that are stored in tag.attr['article_ids'] we can
    # loop over them and output them as per the usual pattern.
    desc %{
      tag: featured_interviews
      description: Featured Interviews
      usage: <r:featured_interviews><r:each></r:each></r:featured_interviews>
      attributes: 
        article_ids:
          legend: Pick Interview Articles
          input: interview_articles_picker
    }
    tag 'featured_interviews' do |tag|
      cache 'featured_interviews' do
        tag.locals.featured_interviews = []
        tag.attr['article_ids'].split(",").each do |id|
          tag.locals.featured_interviews << Article.find_by_id(id)
        end
        tag.locals.featured_interviews.compact!
        tag.expand unless tag.locals.featured_interviews.empty?
      end
    end
    tag 'featured_interviews:each' do |tag|
      returning [] do |result|
        tag.locals.featured_interviews.each do |interview|
          tag.locals.featured_interview = {}
          tag.locals.featured_interview[:title] = interview.full_title
          tag.locals.featured_interview[:url] = contextual_article_path(interview, request.path)
          tag.locals.featured_interview[:author] = (interview.author.nil? || interview.author.blank?) ? "" : "by " + interview.author
          tag.locals.featured_interview[:date] = interview.date.to_s(:mdy_short)
          tag.locals.featured_interview[:comments] = tag_wrapper('a', "Comments", :href => contextual_article_path(interview, request.path)+"/comments") + " (#{interview.comments_count})"
          result << tag.expand
        end
      end
    end
    [:title,:author,:date,:comments,:url].each do |attr|
      tag "featured_interviews:each:#{attr}" do |tag|
        tag.locals.featured_interview[attr]
      end
    end
    
    # Related News
    # The related news widget finds the current article through the URL and then
    # compiles two separate lists of conditions: one that has the articles subjects
    # from 1 month ago, and another that goes back 6 months.
    # Then we go through the News, Blogs, and Opinion section, finding as many
    # articles as we can, first trying the first month, then 6 months.
    # After organizing a list of related news from hopefully as recent as 
    # possible, we loop through them according to the usual pattern.
    tag 'related_news' do |tag|
      article = article_from_url
      primary_conditions = ['subjects.id IN (?) AND date >= (?) AND state = (?) AND articles.id <> (?)',article.subjects.map(&:id),1.month.ago,'approved',article.id]
      alternate_conditions = ['subjects.id IN (?) AND date >= (?) AND state = (?) AND articles.id <> (?)',article.subjects.map(&:id), 6.months.ago, 'approved', article.id]

      tag.locals.related_news = []
      [CACM::NEWS_SECTION,CACM::BLOG_CACM,CACM::OPINION_SECTION].each do |section|    
        #if !section.articles.count(:all, :include => [:subjects],:conditions => primary_conditions).zero?
        #  tag.locals.related_news << section.articles.find(:first, :include => [:subjects ],:conditions => primary_conditions ,:order => "RAND()")
        #else
          tag.locals.related_news << section.articles.find(:first, :include => [:subjects ],:conditions => alternate_conditions, :order => "RAND()")
        #end
      end

      tag.locals.related_news.compact!
      tag.expand unless tag.locals.related_news.empty?
    end
    tag 'related_news:each' do |tag|
      returning [] do |output|
        tag.locals.related_news.each do |related|
          tag.locals.related = related
          tag.locals.related = {}
          tag.locals.related[:link] = contextual_article_path(related,request.path)
          tag.locals.related[:title] = related.full_title
          tag.locals.related[:byline] = related.author
          output << tag.expand
        end
      end
    end
    [:link,:title,:byline].each do |attr|
      tag "related_news:each:#{attr}" do |tag|
        tag.locals.related[attr]
      end
    end
    
    # Promo tags
    # These promo widgets are all controlled through the radiant admin. The 
    # admin will pick an image and a url for each promo widget, and the 
    # widget tag will output the linked promo image, provided that both URL
    # and image are picked and present.
    desc %{
      tag: promo_160_160
      description: Promo Column 1
      usage: <r:promo_160_160 />
      attributes:
        promo_url_1:
          legend: Please enter the link for the first promotion
          input: text
        promo_image_1:
          legend: Please select the first promotional image, which must be 160x160.
          input: asset_picker
    }
    tag "promo_160_160" do |tag|
      cache 'promo_160_160' do
        image = Asset.find(tag.attr['promo_image_1'].to_i) rescue nil
        image_url = tag.attr['promo_url_1']
        if image && image_url
          "<a href='#{image_url}' target='_blank'><img src='#{CGI.escapeHTML(image.public_filename)}' height='160' width='160' alt='#{(image.title.nil? || image.title.blank?) ? image.filename : image.title}' class='promo' /></a>"
        end
      end
    end
    
    desc %{
      tag: promo_160_600
      description: Promo Column 2
      usage: <r:promo_160_600 />
      attributes:
        promo_url_2:
          legend: Please enter the link for the second promotion
          input: text
        promo_image_2:
          legend: Please select the first promotional image, which must be 160x600.
          input: asset_picker
    }
    tag "promo_160_600" do |tag|
      cache 'promo_160_600' do
        image = Asset.find(tag.attr['promo_image_2'].to_i) rescue nil
        image_url = tag.attr['promo_url_2']
        if image && image_url
          "<a href='#{image_url}' target='_blank'><img src='#{CGI.escapeHTML(image.public_filename)}' height='600' width='160' alt='#{(image.title.nil? || image.title.blank?) ? image.filename : image.title}' class='promo' /></a>"
        end
      end
    end

    desc %{
      tag: email_promo
      description: Email Promo
      usage: <r:email_promo />
      attributes:
        promo_url:
          legend: Please enter the full link for the promotion, starting with http://
          input: text
        promo_image:
          legend: Please select the promotional image, which must be 160x600.
          input: asset_picker
    }
    tag "email_promo" do |tag|
      image = Asset.find(tag.attr['promo_image'].to_i) rescue nil
      image_url = tag.attr['promo_url']
      if image && image_url
        "<a href='#{image_url}' target='_blank'><img src='http://#{ActionMailer::Base.default_url_options[:host]}#{CGI.escapeHTML(image.public_filename)}' height='600' width='160' style='border:0px;' alt='#{(image.title.nil? || image.title.blank?) ? image.filename : image.title}' /></a>"
      end
    end
    
    tag "related_articles_by_subject" do |tag|
      if (subject = subject_from_url) and subject.keywords.any?
        query = Endeca::Query.new
        query.terms = subject.keywords
        results = query.query
        tag.locals.results = results.sample(20)
        tag.expand if tag.locals.results.any?
      end
    end

    tag 'related_articles_by_subject:each' do |tag|
      tag.locals.results.collect do |result|
        tag.locals.result = result
        tag.context.define_tag 'article', :for => result, :expose => [:title, :main_parent_title, :url]
        tag.expand
      end.join ' '
    end
    
    tag "related_articles_by_article" do |tag|
      if (article = Article.find_by_id(request.parameters['article'])) and article.keywords.any?
        query = Endeca::Query.new
        query.terms = article.keywords
        results = query.query
        tag.locals.results = results.sample(3)
        tag.expand if tag.locals.results.any?
      end
    end
    
    tag 'related_articles_by_article:each' do |tag|
      tag.locals.results.collect do |result|
        tag.locals.result = result
        tag.context.define_tag 'article', :for => result, :expose => [:title, :main_parent_title, :url]
        tag.expand
      end.join ' '
    end
    
    # The add_tokens tag is used as a radius wrapper for the method
    # add_tokens_to_portal_urls which will add CF_ID and CF_TOKEN to URLs
    # pointing to the digital library, which allows us to store un-tokenized
    # versions in the cache.
    tag 'add_tokens' do |tag|
      html = tag.expand
      return html unless current_member and not current_member.client.blank?
      add_tokens_to_portal_urls(html,current_member.session_id, current_member.session_token)
    end
    
    # # overrides both portal each:article:url tags exposed above
    # tag 'each:article:url' do |tag|
    #   tag.locals.result.url(request.session[:oracle])
    # end
    
    ["News","Opinion","Careers","Blog CACM"].each do |section|
      section_name = section.downcase.underscorize
      tag "most_discussed_#{section_name}" do |tag|
        tag.locals.articles = Article.send("most_discussed_#{section_name}_articles".to_sym)
        tag.expand
      end
      
      tag "most_discussed_#{section_name}:each" do |tag| 
        returning [] do |s|
          tag.locals.articles.each do |article|
            tag.locals.article = {}
            tag.locals.article[:link] = contextual_article_path(article, request.path)
            tag.locals.article[:title] = article.full_title
            tag.locals.article[:date] = article.date.to_s(:date)
            tag.locals.article[:comments] = tag_wrapper('a', "Comments", :href => contextual_article_path(article, request.path)+"/comments") + " (#{article.comments_count})"
            s << tag.expand
          end
        end
      end
      [:link,:title,:date,:comments].each do |attr|
        tag "most_discussed_#{section_name}:each:#{attr}" do |tag|
          tag.locals.article[attr]
        end
      end
    end
    
    tag "most_discussed_articles_for_subject" do |tag|
      if subject = subject_from_url
        tag.locals.articles = Article.most_discussed_articles_for_subject(subject.name)
        tag.expand
      end
    end
    
    tag "most_discussed_articles_for_subject:each" do |tag|
      returning [] do |s|
        tag.locals.articles.each do |article|
          tag.locals.article = {}
          tag.locals.article[:link] = contextual_article_path(article, request.path)
          tag.locals.article[:title] = article.full_title
          tag.locals.article[:date] = article.date.to_s(:date)
          tag.locals.article[:comments] = tag_wrapper('a', "Comments", :href => contextual_article_path(article, request.path)+"/comments") + " (#{article.comments_count})"
          s << tag.expand
        end
      end
    end
    [:link,:title,:date,:comments].each do |attr|
      tag "most_discussed_articles_for_subject:each:#{attr}" do |tag|
        tag.locals.article[attr]
      end
    end

    tag "this_day_in_history" do |tag|

      today = Date.today
      
      # to test out other days
      if (RAILS_ENV == "development" || RAILS_ENV == "staging") && (request.parameters['tdihday'] || request.parameters['tdihmonth'])
        day = request.parameters['tdihday'].nil? ? Date.today.day : request.parameters['tdihday'].to_i
        month = request.parameters['tdihmonth'].nil? ? Date.today.month : request.parameters['tdihmonth'].to_i
        today = Date.civil(Date.today.year, month, day)
      end

      if (tdih = ThisDayInHistory.find(:first, :conditions => ["tdihMonth = ? AND tdihDay = ?", Date::MONTHNAMES[today.month], today.day]))
        returning [] do |s|
          tag.locals.tdih = {}
          tag.locals.tdih[:image] = tdih.image_1.blank? ? "" : "<a href=\"http://www.computerhistory.org/tdih/\" target=\"_blank\"><img src=\"/images/tdih/thumbs/#{tdih.image_1}\" class=\"pic\" width=\"100\" height=\"100\" alt=\"#{tdih.caption_1}\" /></a>"
          tag.locals.tdih[:caption] = tdih.caption_1 || ""
          # yes, I saw some dates without years in the TDIH database.  boo.
          tag.locals.tdih[:date] = tdih.tdihYear.blank? ? today.strftime("%m.%d") : Date.new(tdih.tdihYear.to_i, today.month, today.day).strftime("%m.%d.%Y")
          tag.locals.tdih[:title] = tdih.title
          tag.locals.tdih[:description] = truncate_html(sanitizer.strip_tags(tdih.description), 225, "&hellip;")
          s << tag.expand
        end
      end
    end
    
    [:image, :caption, :alt, :title, :date, :description].each do |attr|
      tag "this_day_in_history:#{attr}" do |tag|
        tag.locals.tdih[attr]
      end
    end

  end
end
