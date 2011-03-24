module CACM
  module RadiusTags
    include Radiant::Taggable
    include CACM::WillPaginateForRadiant::Paginator
    include CACM::SectionsPathHelper
    include CacmHelper
    include TextHelper
    
    class TagError < StandardTags::TagError; end
    
    tag 'get_comments_count' do |tag|
      tag.locals.page["comments_count"] = Hash.new
      Issue.find(tag.attr['issue_id']).articles.find(:all, :select => 'id, comments_count').map {|x| tag.locals.page["comments_count"][x.id] = x.comments_count }
      tag.expand
    end

    tag 'any_comments' do |tag|
      tag.expand if tag.locals.page["comments_count"][tag.attr['article_id'].to_i] && tag.locals.page["comments_count"][tag.attr['article_id'].to_i] > 0
    end
    
    tag 'comments_count' do |tag|
      tag.locals.page["comments_count"][tag.attr['article_id'].to_i]
    end
    
    # Keep these rescue clauses in the _logged_in methods during development as they tend to hide the cause of real errors in the stack
    tag 'if_logged_in' do |tag|
      tag.expand if current_member.indv? rescue false
    end

    tag 'unless_logged_in' do |tag|
      tag.expand unless current_member.indv? rescue true
    end
    
    tag 'current_username' do |tag|
      # rescue just in case, since this is exposed on every page
      current_member.name || current_member.username rescue ""
    end

    # This tag is used to determine if the site is on the live production
    # server inline. E.G. if we're in live production, use minimized javascripts
    # for faster performance but in other environments use the regular 
    # javascript files for easier debugging.
    tag "if_live_production" do |tag|
      tag.expand if ( # this tag wraps the google analytics code, but some places shouldn't be tracked:
        RAILS_ENV == 'production' && # only in the production environment
        request && request.env['SERVER_NAME'].include?('acm.org') && # on the production server
        !request.path_parameters[:action].eql?("preview") && # that isn't a preview
        !request.path_parameters["controller"].eql?("preview") && # or in the preview controller
        !request.path_parameters["controller"].eql?("cacm_admin/articles_preview") # or in the CAE preview controller
      )
    end

    tag "if_local_development" do |tag|
      tag.expand if (RAILS_ENV == 'development')
    end

    tag "unless_local_development" do |tag|
      tag.expand unless (RAILS_ENV == 'development')
    end

    # used to serve ACM's GSA a META tag, preventing it from storing cached versions of our pages
    tag "if_gsa" do |tag|
      tag.expand if request.remote_ip.match(/63\.118\.7\.[34]/)
    end
    
    # This is used on layouts to output section-specific stylesheets on Rails
    # Pages, depending on the current controller.
    tag "controller_css_imports" do |tag|
      controller = request.path_parameters["controller"]
      if controller.eql?("archives")
        %{ @import url(/stylesheets/sections/archive.css); }
      elsif ["magazines","sections","subjects","articles"].include?(controller)
        %{ @import url(/stylesheets/sections/article.css); @import url(/stylesheets/sections/account.css); }
      elsif ["accounts","session"].include?(controller)
        %{ @import url(/stylesheets/sections/account.css); }
      end
    end

    # This is a replication of the display_flash helper in CacmHelper.
    tag "display_flashes" do |tag|
      unless request.session["flash"].nil?
        returning [] do |flashes|
          [:notice,:error,:warning,:comment].each do |f|
            flashes << tag_wrapper("div", request.session["flash"][f], :id => "Flash" + f.to_s.capitalize, :class => "Flash") if request.session["flash"][f] and not request.session["flash"][f].blank?
          end
        end.join("\n")
      end
    end
    
    # This outputs session variables to be sent over to the DL when using our
    # search box. Since the DL search toggling is only enabled via JS, we'll stick
    # the session vars into a hidden input for JS to manipulate.
    tag 'dl_session_tokens_input' do |tag|
      returning [] do |output|
        output << tag_wrapper('input', nil, :value => current_member ? current_member.session_id : "", :name => "CFID", :id => "search_cf_session_id", :type => :hidden)
        output << tag_wrapper('input', nil, :value => current_member ? current_member.session_token : "", :name => "CFTOKEN", :id => "search_cf_session_token", :type => :hidden)
      end.join("\n")
    end
    
    # This will generate a link to the most recent issue, used for places where
    # a link to "Current Issue" is hardcoded and needs to be dynamic
    tag "link_to_current_issue" do |tag|
      issue = Issue.find(:first, :conditions => "state = 'approved'", :order => "pub_date desc") rescue nil
      issue.nil? ? "" : magazine_issue_path(issue.source.pub_date.year, issue.source.pub_date.month)
    end
    
    # These breadcrumbs are used on table of contents and article views. These
    # are determined off the current page request path, matching each potential
    # case. Preview is ignored, and supplements are handled in a separate case.
    # The magazine archive breadcrumbs are drawn differently than the subjects
    # and sections paths, since they are RailsPages, while the subject/sections
    # rely on being able to draw links using page.url, e.g. if the article is
    # being shown in the news section, there is also a Radiant page with the
    # slug of news, so it can draw the first breadcrumb using that pages Radiant
    # title and radiant-generated url.
    
    tag 'breadcrumbs_with_rails' do |tag|
      cache tag.globals.page.request.parameters.symbolize_keys.merge({:fragment => 'breadcrumb'}) do
      begin
        nice_names = {
          "comments" => "Comments",
          "abstract" => "Abstract",
          "fulltext" => "Full Text",
          "pdf" => "PDF",
          "mp3" => "MP3",
          "mov" => "QuickTime Movie", 
          "wmv" => "Windows Media Video",
          "mp4" => "QuickTime MPEG4"
        }

        # Take the separator in to maintain the expected input of the standard breadcrumbs tag
        separator = tag.attr['separator'] || ' &gt; '
        
        # Split up the request path by the slashes but strip the leading slash
        request_path = request.path.split("/")[1..-1]
        
        # If this page is being viewed by preview, just add Preview as part of the breadcrumb and be done with it
        if request_path.include?("preview")
          page = Page.find(:first)
          rails_crumbs = "Preview"

        # Catch the Magazines Here
        elsif request_path.include?("magazines") and not request_path.include?("supplements")
          page = Page.find(:first)
          rails_crumbs = []

          # Iterate over the cleaned request_path
          request_path.each_with_index do |path,index|
            # If there is a fourth element, its "abstract" or "comment" so capitalize it and put it in directly
            if request_path.index(path).eql?(4)
              rails_crumbs << nice_names[path]

            # The third element will always be an article, if it is the last element dont draw the link
            elsif request_path.last.eql?(path) && request_path.index(path).eql?(3)
              rails_crumbs << Article.find(path).full_title

            # Draw the link here then
            elsif request_path.index(path).eql?(3)
              rails_crumbs << "<a href=\"/#{request_path[0..index].join('/')}\">#{truncate_html(Article.find(path).full_title, 50)}</a>"

            # Standard - Last Element has no link
            elsif request_path.last.eql?(path)
              rails_crumbs << "#{(path.length <= 2) ? 'No. ' : ''}#{path}"

            # Standard - All elements except last draw links
            else
              rails_crumbs << "<a href=\"/#{request_path[0..index].join('/')}\">#{(path.length <= 2) ? 'No. ' : ''}#{path.eql?('magazines') ? "Magazine Archive" : path.capitalize}</a>"
            end
          end
          
          rails_crumbs = rails_crumbs.join(separator)
          
        # Supplements Breadcrumbs
        elsif request_path.include?("supplements")
          page = Page.find(:first)
          rails_crumbs = []
          
          # /magazines/:year/:month/:article
          if request_path.include?("magazines")
            
            rails_crumbs << "<a href=\"/magazines\">Magazine Archive</a>"
            rails_crumbs << "<a href=\"/magazines/#{request_path[1]}\">#{request_path[1]}</a>"
            rails_crumbs << "<a href=\"/magazines/#{request_path[1]}/#{request_path[2]}\">No. #{request_path[2]}</a>"
            rails_crumbs << "<a href=\"/magazines/#{request_path[1]}/#{request_path[2]}/#{request_path[3]}\">#{truncate_html(Article.find(request_path[3]).full_title, 50)}</a>"
            
          # /browse-by-subject
          elsif request_path.include?("browse-by-subject")
            
            rails_crumbs << "<a href=\"/browse-by-subject\">Browse by Subject</a>"
            rails_crumbs << "<a href=\"/browse-by-subject/#{request_path[1]}\">#{Subject.find(request.path_parameters[:subject]).name.titleize}</a>"
            rails_crumbs << "<a href=\"/browse-by-subject/#{request_path[1]}/#{request_path[2]}\">#{truncate_html(Article.find(request_path[2]).full_title, 50)}</a>"
            
          # /blogs/blog-cacm/:article
          elsif request_path.include?("blogs")
            
            rails_crumbs << "<a href=\"/blogs\">Blogs</a>"
            rails_crumbs << "<a href=\"/blogs/blog-cacm\">blog@CACM</a>"
            rails_crumbs << "<a href=\"/blogs/blog-cacm/#{request_path[2]}\">#{truncate_html(Article.find(request_path[2]).full_title, 50)}</a>"
            
            
          elsif request_path.include?("news") or request_path.include?("careers")
            
            rails_crumbs << "<a href=\"/#{request_path[0]}\">#{request_path[0].titleize}</a>"
            rails_crumbs << "<a href=\"/#{request_path[0]}/#{request_path[1]}\">#{truncate_html(Article.find(request_path[1]).full_title, 50)}</a>"
          
          elsif request_path.include?("opinion")
            
            rails_crumbs << "<a href=\"/opinion\">Opinion</a>"
            rails_crumbs << "<a href=\"/opinion/#{request_path[1]}\">#{request_path[1].titleize}</a>"
            rails_crumbs << "<a href=\"/opinion/#{request_path[1]}/#{request_path[2]}\">#{truncate_html(Article.find(request_path[2]).full_title, 50)}</a>"
            
          end
          
          # Try to find the article, then the source, then the supplement,
          # then grab the link_txt for the end of the breadcrumb. Rescuing nil.
          supplement_name = Article.find(request.path_parameters["article"]).source.supplements[request.path_parameters["id"].to_i-1].link_txt rescue nil
          rails_crumbs << supplement_name ? supplement_name : "Supplement ##{request_path.last}"

          rails_crumbs = rails_crumbs.join(separator)
          
        # Catch all other rails pages (assumption is that they are Article pages)
        else
          rails_crumbs = []

          if ["comments","abstract","fulltext", "pdf","mp3","mov","wmv","mp4"].include?(request_path.last)
            rails_crumbs << nice_names[request_path.pop]
            rails_crumbs << "<a href=\"/#{request_path.join('/')}\">#{truncate_html(Article.find(request_path.pop).full_title, 50)}</a>"
            rails_crumbs.reverse!
          else
            rails_crumbs << truncate_html(Article.find(request_path.pop).full_title, 50)
          end

          rails_crumbs = rails_crumbs.join(separator)
            
          page = Page.find_by_url(request_path.join('/'))

        end

        # Now Revert to the Standard Breadcrumbs Logic (slightly modified)
        breadcrumbs = ["<a href=\"#{page.url}\">#{page.breadcrumb}</a>"]
        nolinks = (tag.attr['nolinks'] == 'true')
        page.ancestors.each do |ancestor|
          tag.locals.page = ancestor
          if nolinks
            breadcrumbs.unshift tag.render('breadcrumb')
          else
            breadcrumbs.unshift %{<a href="#{tag.render('url')}">#{tag.render('breadcrumb')}</a>}
          end
        end
        
        # Combine the crumbs if there are rails crumbs
        breadcrumbs << rails_crumbs if rails_crumbs
        
        # Join the array with the separator and present
        breadcrumbs.join(separator)
      rescue
        ""
      end
      end
    end
    
    # Section Nav is used on all section navigation snippets. 
    # See documentation for this tag, and how it is futher customized, in:
    # /vendor/extensions/dp/lib/radius_tags.rb:29
    # View the actual usage in the design folder:
    # /design/snippets/secondary_nav*.html
    
    tag 'section_nav' do |tag|
      tag.locals.levels = levels = (tag.attr['levels'] || 1).to_i
      tag.locals.level = 1
      hash = tag.locals.section_nav = {}
      tag.expand
      raise TagError.new("`section_nav' tag must include a `normal' tag") unless hash.has_key? :normal
      section_page = tag.globals.page.ancestors.size >= 2 ? tag.globals.page.ancestors[-2] : tag.globals.page
      tag.locals.page = section_page
      returning String.new do |output|
        unless section_page.children.empty?
          output << '<ul id="SideNav">' unless tag.attr['no_list']
          output << tag.render('render_level')
          output << '</ul>' unless tag.attr['no_list']
        end
      end
    end

    [:normal, :selected, :selected_childless].each do |symbol|
      tag "section_nav:#{symbol}" do |tag|
        hash = tag.locals.section_nav
        hash[symbol] = tag.block
      end
    end

    tag 'section_nav:render_level' do |tag|
      page = tag.locals.page
      children = page.children.find(:all, children_find_options(tag))
      hash = tag.locals.section_nav
      between = hash[:between] ? hash[:between].call : ''
      returning [] do |result|
        children.each do |child|
          tag.locals.page = child
          compare_url = remove_trailing_slash(child.url)
          page_url = remove_trailing_slash(tag.globals.page.url)
          if child.class_name == "RailsPage"
            if page_url.include? compare_url
              result << hash[:selected_childless].call # selected, but no sublist
            else
              result << hash[:normal].call
            end
          else
          case page_url
            when compare_url
              if child.children.any?
                result << (hash[:selected]).call # selected, but heading the child sublist
              else
                result << (hash[:selected_childless]).call # selected, but no sublist
              end
            when Regexp.new("^" + Regexp.quote(remove_trailing_slash(compare_url)) + "(/|\Z)")
              result << (hash[:selected] || hash[:normal]).call
            else
              result << hash[:normal].call
            end
          end
        end
      end.join(between)            
    end

    tag 'section_nav:next_level' do |tag|
      if tag.locals.level < tag.locals.levels
        tag.locals.level += 1
        tag.expand
      end
    end
    
    # The if/unless_section tags are treating 'section' as the first slug
    # in the path. e.g. "news", "opinion", "blogs"...
    tag 'if_section' do |tag|
      raise TagError.new("`if_section` tag needs a `section` tag, which should be a page slug") unless tag.attr['section']
      section = tag.locals.page.ancestors[-2] || tag.locals.page
      if section.slug.eql?(tag.attr['section'])
        tag.expand
      elsif tag.locals.page.class_name.eql?("RailsPage") # ancestors isn't too helpful on sections in this case
        tag.expand if request.path.split("/")[1].eql?(tag.attr['section'])
      end
    end

    tag 'unless_section' do |tag|
      raise TagError.new("`unless_section` tag needs a `section` tag, which should be a page slug") unless tag.attr['section']
      section = tag.locals.page.ancestors[-2] || tag.locals.page
      tag.expand unless section.slug.eql?(tag.attr['section'])
    end
 
    tag 'if_depth' do |tag|
     raise TagError.new("`if_depth` tag needs a `level` tag, which should be an integer") unless tag.attr['level']
     tag.expand if tag.locals.page.ancestors.length >= tag.attr['level'].to_i
    end

    tag 'unless_depth' do |tag|
     raise TagError.new("`unless_depth` tag needs a `level` tag, which should be an integer") unless tag.attr['level']
     tag.expand unless tag.locals.page.ancestors.length >= tag.attr['level'].to_i
    end
    
    # Returns the correct RSS link tag for the current page, or nothing if
    # there is no RSS feed available for the current page.
    tag 'rss_link_tag' do |tag|
      url = tag.globals.page.url.split("/")
      url = url[1] # check where we are on the site

      title = "Communications of the ACM: "

      tag.locals.rss_url = case url
      when "opinion"
        title += "Opinions Articles"
        "/opinion.rss"
      when "blogs"
        title += "blog@CACM Articles"
        "/blogs/blog-cacm.rss"
      when "careers"
        title += "Careers Articles"
        "/careers.rss"
      when "news"
        title += "News Articles"
        "/news.rss"
      when "magazines"
        title += "Current Issue"
        "/magazine.rss"
      when "browse-by-subject"
        subject = Subject.find_by_name(tag.globals.page.title)
        if subject
          title += "#{tag.globals.page.title} Articles"
          "/browse-by-subject/#{subject.to_param}.rss"
        end
      when nil
        # we're on the homepage - provide the magazine feed
        title += "Current Issue"
        "/magazine.rss"
      end

      title += " [RSS 2.0]"

      return tag.locals.rss_url.nil? ? "" : tag_wrapper('link', nil, {:rel => "alternate", :type => "application/rss+xml", :href => tag.locals.rss_url, :title => title })
    end
    
    # Outputs RSS links for the subject feeds
    tag 'subject_rss_url' do |tag|
      # if we've got 'subject' in the page's url, find by subject; otherwise, use sections
      if (tag.globals.page.url.index("subject"))
        url = tag.globals.page.url.split("/")
        url = url[url.length-1]
        subject = Subject.find_by_name(tag.globals.page.title)
        tag.locals.rss_url = "/browse-by-subject/#{subject.to_param}.rss"
      end
      return tag.locals.rss_url.nil? ? "" : tag.locals.rss_url
    end
    
    # This tag is used on the featured_summary snippet, which is used on
    # many landing pages to display that section or subjects featured
    # article. It finds the page part for featured article which is set by the
    # Radiant admin. This is the ID of the article - we then find the article,
    # find all the necessary display values that we need for to display the 
    # snippet, and gather all the values in a hash. We then use an array of
    # each value to create a radius tag to output each piece of data, which
    # correlates to the keys in the article hash.
    
    tag 'featured_summary' do |tag|
      part = tag.globals.page.part(:featured_article)
      article_id = part.nil? ? nil : part.content
      if article_id.nil? or article_id.empty?
        tag.locals.article = nil
      else # assocation was made, article was found
        tag.locals.article = article_id.nil? ? nil : Article.find(article_id)
        tag.locals.article = nil if tag.locals.article.state != 'approved' # can't feature un-approved articles!
      end
      unless tag.locals.article.nil?
        # Set up all the various pieces that will need to be returned as a radius tag
        tag.locals.featured_summary = {}
        tag.locals.featured_summary[:title] = tag.locals.article.full_title
        tag.locals.featured_summary[:byline] = "From " + tag.locals.article.feed.name
        tag.locals.featured_summary[:summary] = (tag.locals.article.short_description.nil? or tag.locals.article.short_description.empty?) ? "" : truncate_html(tag.locals.article.short_description, 225, "&hellip;")
        tag.locals.featured_summary[:date] = tag.locals.article.date.strftime(DP::DATE_TIME_FORMATS[:date])
        tag.locals.featured_summary[:author] = tag.locals.article.author
        tag.locals.featured_summary[:url] = tag.locals.article.is_syndicated_blog_post? ? CGI.escapeHTML(tag.locals.article.link) : CGI.escapeHTML(contextual_article_path(tag.locals.article, tag.globals.page.url))
        tag.locals.featured_summary[:target] = tag.locals.article.is_syndicated_blog_post? ? "target=\"_blank\"" : ""
        image = tag.locals.article.image.nil? ? nil : tag.locals.article.image
        # Check for article image's existence. Store an image tag for both the
        # r:image and r:thumbnail, which is only used on the careers landing
        # page. Check the featured_summary snippet for details. -amlw 12/29
        tag.locals.featured_summary[:image] = image.nil? ? "" : tag_wrapper('img', nil, :src => CGI.escapeHTML(image.public_filename(:medium)), :height => 160, :width => 160, :alt => CGI.escapeHTML(image.title), :class => :pic)
        tag.locals.featured_summary[:thumbnail] = image.nil? ? "" : tag_wrapper('img', nil, :src => CGI.escapeHTML(image.public_filename(:small_square)), :height => 100, :width => 100, :alt => CGI.escapeHTML(image.title), :class => :pic)
        tag.locals.featured_summary[:comments] = tag.locals.article.comments_count > 0 ? tag_wrapper("a", "#{tag.locals.article.comments_count} Comment#{tag.locals.article.comments_count > 1 ? 's' : ''}", :href => "#{contextual_article_path(tag.locals.article,request.path)}/comments") : nil
        
        # Make sure there isn't a default image to use
        if tag.locals.featured_summary[:image].blank? && feed = tag.locals.article.feed
          if feed.feed_type.name.eql?("Blog") && feed.default_article_image
            tag.locals.featured_summary[:image] = tag_wrapper("img", nil, :src => CGI.escapeHTML(feed.default_article_image.public_filename(:medium)), :height => 160, :width => 160, :alt => CGI.escapeHTML(tag.locals.article.full_title), :class => :pic)
          end
        end
        
        tag.expand
      end
    end
    [:title,:byline,:summary,:date,:author,:url,:target,:image,:thumbnail,:comments].each do |attr|
      tag "featured_summary:#{attr}" do |tag|
        return tag.locals.featured_summary[attr]
      end
    end
    tag "featured_summary:if_comments" do |tag|
      tag.expand unless tag.locals.featured_summary[:comments].nil?
    end
    
    
    # The latest_articles tag is used in the article_summaries snippet, which
    # is in turn used on pretty much every listing page. The first part of this
    # tag just figures out which page listing we're dealing with (subject, or
    # section?) and performs the query for our listing, paginated for the 
    # current listing page.
    # The second part of the tag (:each) is the iterator that loops over each
    # article returned by our query, and stashes all of the necessary values
    # for output into a hash. We then loop over the values, creating a radius
    # tag for each value. When we go through the :each statement in the markup,
    # we start to call each of the sub-tags, which in turn fetch the latest
    # value from the article hash.
    
    tag 'latest_articles' do |tag|
      tag.locals.current_page = tag.globals.page.request.parameters['p']
      # if we've got 'subject' in the page's url, find by subject; otherwise, use sections
      if (tag.globals.page.url.index("subject"))
        subject = Subject.find_by_name(tag.globals.page.title)
        tag.locals.articles = Article.paginate(:all, :page => tag.locals.current_page, :include => [:subjects, :sections], :order => 'approved_at DESC',
                                               :conditions => ["feed_id IN (?) AND subjects.id = ? AND state = 'approved'",
                                                                Feed.find_all_by_name(["Communications of the ACM", "blog@CACM"], :select => :id).map(&:id),
                                                                subject.id],
                                               :per_page => Subject.per_page)
      else
        url = tag.globals.page.url.split("/")
        url = url[url.length-1] # grab the last part of the URL to see where we are
        tag.locals.articles = case url
        when "articles"
          Section.find_by_name("opinion").articles.paginate(:page => tag.locals.current_page, :per_page => Section.per_page)
        when "opinion"
          Section.find_by_name("opinion").all_articles(:page => tag.locals.current_page, :per_page => Section.per_page)
        when "blogs"
          Section.find_by_name("blogs").all_articles(:page => tag.locals.current_page, :per_page => Section.per_page)
        else
          Section.find_by_name(url.gsub(/[-]/, ' ')).articles.paginate(:per_page => Section.per_page, :page => tag.locals.current_page)
        end
      end
      # remove featured article from list
      featured = tag.globals.page.part('featured_article')
      tag.locals.articles.delete_if {|a| a.id == featured.content.to_i} if featured
      tag.locals.articles.compact!
      # anything left?
      if tag.locals.articles.any?
        tag.locals.sources = Oracle::Article.find(tag.locals.articles.map(&:oracle_id).compact, :include => :section)
        tag.expand
      end
    end
    
    tag 'latest_articles:each' do |tag|
      returning [] do |output|
        tag.locals.articles.each do |article|
          source = tag.locals.sources.find { |s| s.id == article.oracle_id }
          tag.locals.article = article
          tag.locals.article_url = tag.locals.article.is_syndicated_blog_post? ? tag.locals.article.link : contextual_article_path(tag.locals.article, tag.globals.page.url)
          
          # Set up various data to send back via radius tags
          tag.locals.latest_article = {}
          tag.locals.latest_article[:title] = tag.locals.article.is_dl_article? ? tag.locals.article.full_title : CGI.escapeHTML(tag.locals.article.title)
          tag.locals.latest_article[:byline] = "From " + CGI.escapeHTML(tag.locals.article.feed.name)
          tag.locals.latest_article[:article] = article
          
          # Correct Setting Of the SlugLINE Stuff
          # Does the article have a CACM-based section assignment?
          tag.locals.latest_article[:slugline] = tag.locals.article.sections.first.name rescue nil
          # Okay, does the Oracle article have a section title?
          tag.locals.latest_article[:slugline] = tag.locals.latest_article[:slugline].nil? ? source.section.title : tag.locals.latest_article[:slugline] rescue "Communications"
          # (Still rescuing with Communications if no section is present)
          tag.locals.latest_article[:slugline] = "blog@CACM" if tag.locals.latest_article[:slugline].eql?("Blog CACM")
          # Replace "Blog CACM" with "blog@CACM"
          
          tag.locals.latest_article[:summary] = (tag.locals.article.short_description.nil? or tag.locals.article.short_description.empty?) ? "" : truncate_html(tag.locals.article.short_description, 225, "&hellip;")
          case url.split('/')[1]
          when 'news', 'careers', 'opinion'
            tag.locals.latest_article[:date] = tag.locals.article.date.strftime(DP::DATE_TIME_FORMATS[:date])
          when 'blogs'
            tag.locals.latest_article[:date] = tag.locals.article.date.strftime(DP::DATE_TIME_FORMATS[:long])
          else
            tag.locals.latest_article[:date] = tag.locals.article.date.strftime(DP::DATE_TIME_FORMATS[:calendar])
          end
          tag.locals.latest_article[:author] = CGI.escapeHTML(tag.locals.article.author)
          tag.locals.latest_article[:url] = CGI.escapeHTML(tag.locals.article_url) # damn ampersands!
          tag.locals.latest_article[:target] = tag.locals.article.is_syndicated_blog_post? ? "target=\"_blank\"" : ""
          tag.locals.latest_article[:comments_count] = tag.locals.article.comments_count
          output << tag.expand

        end
      end
    end
    
    # These are the strict output tags that just return one of the values
    # stored above for the article that is currently being iterated over.
    [:title,:slugline,:summary,:date,:author,:url,:target,:comments_count].each do |attr|
      tag "latest_articles:each:#{attr}" do |tag|
        return tag.locals.latest_article[attr]
      end
    end
    
    # This output tag is similar to the ones above but contains too much
    # conditional logic to sanely capture in the latest_articles:each tag.
    tag 'latest_articles:each:byline' do |tag|
      article = tag.locals.latest_article[:article]
      returning [] do |s|
        s << "From "
        if article.is_dl_article?
          if article.class.to_s != "CacmArticle" && article.class.to_s != "DLArticle"
            title = article.source_human_name
            title.slice!(0..4)
            s << title
          elsif article.class.to_s == "DLArticle" 
            s << "Communications of the ACM"
          else
            s << article.feed.name
          end
        else
         s << article.feed.name
        end
      end
    end
    
    # Another :each output tag with too much asset-related logic to pack into
    # the article iteration collection tag sanely.
    tag 'latest_articles:each:article_listing_thumbnail' do |tag|
      image_thumbnail_for_article_summary(tag.locals.article, tag.locals.article_url)
    end
    
    # This conditionally expands if there are any comments, saving us from
    # outputting invalid or empty markup containers in the snippet.
    tag 'latest_articles:each:if_comments' do |tag|
      tag.expand if tag.locals.article.comments_count > 0
    end
    
    # This is actually output outside of the iteration, at the end of this
    # latest_articles tag- it uses will_paginate_radiant to output the pagination
    # numbers at the bottom of the listing, using the current page parameters,
    # after deleting common ones.
    tag 'latest_articles:pagination_links' do |tag|
      collected_params = tag.globals.page.request.parameters.reject { |key, value| key == "action" || key == "controller" || value == "" || key == "p" || key == 'url'}
      will_paginate_radiant(tag.locals.articles, collected_params)
    end

    # The article archives are very similar to the latest_articles, in that
    # the main wrapping tag performs a query that returns a batch of articles,
    # and then we iterate over each of the results, query for data on each of
    # the articles, and then output them using the hash/array tag pattern.
    tag 'archive_articles' do |tag|
      tag.locals.current_page = tag.globals.page.request.parameters['p'] ||= '1'
      
      url = tag.globals.page.url.split("/")
      if url.length > 2 && url[2] == 'archive' # archive url format: /[section]/archive?month=xx&year=xxxx 
        # Rescue in case of malformed parameters
        tag.locals.archive_month = tag.globals.page.request.parameters[:month_and_year].nil? ? Time.now.month : tag.globals.page.request.parameters[:month_and_year].split("-").first.to_i rescue Time.now.month
        tag.locals.archive_year = tag.globals.page.request.parameters[:month_and_year].nil? ? Time.now.year : tag.globals.page.request.parameters[:month_and_year].split("-").last.to_i rescue Time.now.year
        tag.locals.articles = Section.find_by_name(url[1]).all_articles_by_year_month(:year => tag.locals.archive_year, :month => tag.locals.archive_month, :page => tag.locals.current_page)
      end
      tag.locals.articles.compact!
      unless tag.locals.articles.nil?
        if tag.locals.articles.empty?
          return tag_wrapper('p', "There are no archived #{url[1]} articles for this time period.") # doh, empty month/year combo!
        else
          tag.locals.sources = Oracle::Article.find(tag.locals.articles.map(&:oracle_id).compact)
          tag.expand # expand the listings!
        end
      end
    end
    
    tag 'archive_articles:each' do |tag|
      returning [] do |output|
        tag.locals.articles.each do |article|
          tag.locals.article = article
          source = tag.locals.sources.find { |s| s.id == article.oracle_id }
          tag.locals.article_url = tag.locals.article.is_syndicated_blog_post? ? tag.locals.article.link : contextual_article_path(tag.locals.article, tag.globals.page.url)
          # Set up various data to send back via radius tags
          tag.locals.archive_article = {}
          tag.locals.archive_article[:title] = tag.locals.article.is_dl_article? ? tag.locals.article.full_title : CGI.escapeHTML(tag.locals.article.title)
          tag.locals.archive_article[:byline] = "From " + CGI.escapeHTML(tag.locals.article.feed.name)
          
          # Does the article have a CACM-based section assignment?
          tag.locals.archive_article[:slugline] = tag.locals.article.sections.first.name rescue nil
          # Okay, does the Oracle article have a section title?
          tag.locals.archive_article[:slugline] = tag.locals.archive_article[:slugline].nil? ? source.section.title : tag.locals.archive_article[:slugline] rescue "Communications"
          # (Still rescuing with Communications if no section is present)
          tag.locals.archive_article[:slugline] = "blog@CACM" if tag.locals.archive_article[:slugline].eql?("Blog CACM")
          
          tag.locals.archive_article[:summary] = (tag.locals.article.short_description.nil? or tag.locals.article.short_description.empty?) ? "" : truncate_html(tag.locals.article.short_description, 225, "&hellip;")
          case url.split('/')[1]
          when 'news', 'opinion'
            tag.locals.archive_article[:date] = tag.locals.article.date.strftime(DP::DATE_TIME_FORMATS[:date])
          when 'blogs'
            tag.locals.archive_article[:date] = tag.locals.article.date.strftime(DP::DATE_TIME_FORMATS[:long])
          else
            tag.locals.archive_article[:date] = tag.locals.article.date.strftime(DP::DATE_TIME_FORMATS[:calendar])
          end
          tag.locals.archive_article[:author] = CGI.escapeHTML(tag.locals.article.author)
          tag.locals.archive_article[:url] = CGI.escapeHTML(tag.locals.article_url) # damn ampersands!
          tag.locals.archive_article[:target] = tag.locals.article.is_syndicated_blog_post? ? "target=\"_blank\"" : ""
          tag.locals.archive_article[:comments_count] = tag.locals.article.comments_count
          output << tag.expand
        end
      end.join("\n")
    end
    [:title,:byline,:slugline,:summary,:date,:author,:url,:target,:comments_count].each do |attr|
      tag "archive_articles:each:#{attr}" do |tag|
        return tag.locals.archive_article[attr]
      end
    end
    tag 'archive_articles:pagination_links' do |tag|
      collected_params = tag.globals.page.request.parameters.reject { |key, value| key == "action" || key == "controller" || value == "" || key == "p" || key == 'url'}
      will_paginate_radiant(tag.locals.articles, collected_params)
    end
    tag 'archive_articles:each:article_listing_thumbnail' do |tag|
      image_thumbnail_for_article_summary(tag.locals.article, tag.locals.article_url)
    end
    tag 'archive_articles:each:if_comments' do |tag|
      tag.expand if tag.locals.article.comments_count > 0
    end
    
    # This is used to output the month/year headers in the archive month and
    # year snippet, based off the page GET parameters.
    tag 'archive_month_and_year' do |tag|
      # Rescue in case of malformed parameters
      month = tag.globals.page.request.parameters[:month_and_year].nil? ? Time.now.month : tag.globals.page.request.parameters[:month_and_year].split("-").first.to_i rescue Time.now.month
      year = tag.globals.page.request.parameters[:month_and_year].nil? ? Time.now.year : tag.globals.page.request.parameters[:month_and_year].split("-").last.to_i rescue Time.now.year
      
      "#{Date::MONTHNAMES[month]} #{year}"
    end
    
    # This is used on the homepage for the main featured article display. On
    # the Radiant page interface the homepage has two fields, one for the article
    # that should be featured, and another for the image to use to display it.
    # This radius tag finds the featured article and draws a links the picked
    # image to the featured article.
    tag 'homepage_featured_article' do |tag|
      tag.locals.featured_article = Article.find(tag.locals.page.part('featured_article').content) rescue nil
      tag.locals.featured_image = Asset.find(tag.locals.page.part('featured_splash_image').content) rescue nil
      tag.locals.featured_video_caption = Asset.find(tag.locals.page.part('featured_video_caption').content) rescue nil
      tag.expand unless tag.locals.featured_article.nil?
    end
    tag 'homepage_featured_article:featured_url' do |tag|
      contextual_article_path(tag.locals.featured_article, tag.locals.page.url)
    end
    tag 'homepage_featured_article:featured_image' do |tag|
      if File.exist?(RAILS_ROOT + "/public" + tag.locals.featured_image.public_filename.split("?").first)
        "<img src=\"#{CGI.escapeHTML(tag.locals.featured_image.public_filename)}\" alt=\"#{CGI.escapeHTML(tag.locals.featured_article.full_title)}\" />"
      end
    end
    tag 'homepage_featured_article:featured_video_caption' do |tag|
      return '' unless tag.locals.featured_video_caption
      if File.exist?(RAILS_ROOT + "/public" + tag.locals.featured_video_caption.public_filename.split("?").first)
        "<img src=\"#{CGI.escapeHTML(tag.locals.featured_video_caption.public_filename)}\" alt=\"#{CGI.escapeHTML(tag.locals.featured_article.full_title)}\" />"
      end
    end
    
    tag 'if_comments_enabled' do |tag|
      article = Article.find(request.parameters[:article]) rescue nil
      tag.expand unless article.nil? || !article.user_comments
    end
    
    # Since the bylines for articles are usually output using SPAN.separater
    # elements in between different parts of the article, we need conditionally
    # expanding tags like if_author to determine if we should output the 
    # span that separates the article authors name from the article date.
    tag 'if_author' do |tag|
      tag.expand unless tag.locals.article.author.nil?
    end
    
    # This tag handles all article meta tag output. Radiant pages output
    # their natural meta data, but for articles several other meta tags are
    # output for the Google Search Appliance to index. It also will output
    # a `robots`=`noindex` tag to avoid duplicate entries in the GSA.
    tag 'article_meta_tags' do |tag|
      meta = []

      # if we're a Radiant page, output the page metadata attributes
      if tag.locals.page.class == Page
        meta << %{<meta name="keywords" content="#{CGI.escapeHTML(tag.locals.page.keywords)}" />}
        meta << %{<meta name="description" content="#{CGI.escapeHTML(tag.locals.page.description)}" />}

      # else we're a Rails page. let's check to see if we're an article
      elsif request.parameters[:article]
        article = Article.find(request.parameters[:article]) rescue nil
        if article
          # standard tags
          meta << %{<meta name="keywords" content="#{CGI.escapeHTML(article.keyword)}" />} unless article.keyword.blank?
          meta << %{<meta name="description" content="#{CGI.escapeHTML(article.description)}" />} unless article.description.blank?

          # for the google search appliance
          meta << %{<meta name="title" content="#{CGI.escapeHTML(sanitizer.strip_tags(article.full_title))}" />} unless article.full_title.blank?
          meta << %{<meta name="author" content="#{CGI.escapeHTML(sanitizer.strip_tags(article.author))}" />} unless article.author.blank?
          meta << %{<meta name="date" content="#{CGI.escapeHTML(article.date.to_s(:iso8601))}" />} unless article.date.blank?

          # exclude the article from indexing unless it's the canonical path.
          # additionally, exclude the abstract view (the GSA has access to 
          # the fulltext by default), PDF, and other "fulltext" views
          # 
          # example:
          #   request.path                     => "/magazines/2009/2/19313-photographys-bright-future/fulltext"
          #   contextual_article_path(article) => "/magazines/2009/2/19313-photographys-bright-future"
          
          if ( 
            !request.path.starts_with?(contextual_article_path(article)) || 
            request.path.ends_with?("/abstract") || 
            request.path.ends_with?("/pdf") ||
            request.path.ends_with?("/mp3") ||
            request.path.ends_with?("/mov") ||
            request.path.ends_with?("/wmv") ||
            request.path.ends_with?("/mp4")
          )
            meta << %{<meta name="robots" content="noindex" />}
          end
        end
      end

      meta.join("\n\t")
    end
    
    # This tag outputs the two SELECTs used on the article archives, month and
    # year which are used to navigate backwards through the archives. Since
    # these are radiant pages, radius tags are used to output the form elements.
    tag "options_for_archives" do |tag|
      # One parameter is used for both month and year, separated by a hyphen
      current_month = request.parameters[:month_and_year] ? request.parameters[:month_and_year].split("-").first.to_i : 0
      current_year = request.parameters[:month_and_year] ? request.parameters[:month_and_year].split("-").last.to_i : 1900
      section = Section.find_by_name(tag.globals.page.url.split("/")[1])
      earliest_article = section.earliest_article
      latest_article = section.latest_article
      
      returning [] do |options|
        
        # Earliest year, starting from the earliest article
        earliest_article.date.month.upto(12) do |month|
          option_attributes = (current_month.eql?(month) && current_year.eql?(earliest_article.date.year)) ? { :value => month.to_s + "-" + earliest_article.date.year.to_s, :selected => "selected" } : { :value => month.to_s + "-" + earliest_article.date.year.to_s }
          options << tag_wrapper('option', month_from_number(month.to_s) + " " + earliest_article.date.year.to_s, option_attributes)
        end
        
        # Middle Years
        range = (earliest_article.date.year..latest_article.date.year).map
        range.slice!(0) # drop first year, taken care of separately
        range.slice!(-1) # drop last year, taken care of separately
        range.each do |year|
          1.upto(12) do |month|
            option_attributes = (current_month.eql?(month) && current_year.eql?(year)) ? { :value => month.to_s + "-" + year.to_s, :selected => "selected" } : { :value => month.to_s + "-" + year.to_s }
            options << tag_wrapper('option', month_from_number(month.to_s) + " " + year.to_s, option_attributes)
          end
        end
        
        # Last Year, ending at the latest article
        1.upto(latest_article.date.month) do |month|
          option_attributes = (current_month.eql?(month) && current_year.eql?(latest_article.date.year)) ? { :value => month.to_s + "-" + latest_article.date.year.to_s, :selected => "selected" } : { :value => month.to_s + "-" + latest_article.date.year.to_s }
          options << tag_wrapper('option', month_from_number(month.to_s) + " " + latest_article.date.year.to_s, option_attributes)
        end
        
      end.reverse.join("\n")
    end
    
    # The page title tag is used on every page. If the current page is a Radiant
    # page then we do a little bit of conditonal logic (for subjects and the 
    # homepage, as the titles for those pages aren't quite right), as well as
    # tacking " | Communications of the ACM" onto the end. If it is a RailsPage
    # then we do a bit more controller sniffing to use the correct title, 
    # using similar logic as in the breadcrumbs. 
     
    tag 'cacm_page_title' do |tag|
      if tag.globals.page.class_name.eql?("RailsPage")
        
        case request.path_parameters[:controller] # try to figure it out based on controller/action...
        
        when "archives"
          case request.path_parameters[:action]
          when "index"
            "Magazine Archive | Communications of the ACM"
          when "toc"
            "#{month_from_number(request.parameters[:month].to_s)} #{request.parameters[:year]} Table of Contents | Communications of the ACM"
          when "year"
            "#{request.parameters[:year]} Issues | Communications of the ACM"
          end
          
        when "articles"
          case request.path_parameters[:action]
          when "show" || "comments"
            if request.request_uri.include?("browse-by-subject")
              # try to get the subject
              subject_title = request.request_uri.split("/")[-2].titleize + "| " rescue ""
              subject_title = "blog@CACM | " if subject_title.eql?("Blog Cacm | ")
              "#{h(sanitizer.strip_tags(@article.full_title))} | #{subject_title}Communications of the ACM"
            else # else this article is viewed through date URL
              "#{h(sanitizer.strip_tags(@article.full_title))} | #{@article.date.to_s(:calendar)} | Communications of the ACM"
            end
          when "abstract"
            "Abstract: #{h(sanitizer.strip_tags(@article.full_title))} | Communications of the ACM"
          end
        
        when "magazines"
          article_title = (Article.find(request.parameters[:article]).full_title + " | ") rescue ""
          "#{h(sanitizer.strip_tags(article_title))}#{month_from_number(request.parameters[:month].to_s)} #{request.parameters[:year]} | Communications of the ACM"
        
        when "subjects"
          article_title = (Article.find(request.parameters[:article]).full_title + " | ") rescue ""
          subject_title = (Subject.find(request.parameters[:subject]).name.titleize + " | ") rescue ""
          subject_title = "blog@CACM | " if subject_title.eql?("Blog Cacm | ")
          "#{h(sanitizer.strip_tags(article_title))}#{subject_title}Communications of the ACM"
          
        when "sections"
          article_title = (Article.find(request.parameters[:article]).full_title + " | ") rescue ""
          section_title = (Section.find(request.parameters[:section]).name.titleize + " | ") rescue ""
          section_title = "blog@CACM | " if section_title.eql?("Blog Cacm | ")
          "#{h(sanitizer.strip_tags(article_title))}#{section_title}Communications of the ACM"
          
        when "search"
          "Search results for \"#{request.parameters[:q]}\" | Communications of the ACM"
        
        when "session"
          "Sign In | Communications of the ACM"
          
        when "accounts"
          
          if ["new","create","verify","complete"].include?(request.path_parameters[:action])
            "Create a Web Account | Communications of the ACM"
          elsif ["forgot","question","edit","update"].include?(request.path_parameters[:action])
            "Forgot Your Password | Communications of the ACM"
          end
          
        else
          "Communications of the ACM"
        
        end
      else # radiant page, but let's check for homepage first...
        if request.request_uri.eql?("/")
          "Communications of the ACM"
        else
          if request.request_uri.match(/browse-by-subject\/./) # are we browsing a subject right now?
            "#{tag.globals.page.title} | Browse by Subject | Communications of the ACM"
          else
            if request.parameters[:month_and_year] # we must be browsing an archives page!
              "#{month_from_number(request.parameters[:month_and_year].split("-").first.to_s)} #{request.parameters[:month_and_year].split("-").last} | #{tag.globals.page.title} | Communications of the ACM"
            else # bah, it's just some radiant page.
              "#{tag.globals.page.title} | Communications of the ACM"
            end
          end
        end
      end
    end
    
    tag "digital_library_search_form_action" do |tag|
      if current_member && current_member.session_id && !current_member.session_id.blank?
        "http://portal.acm.org/results.cfm?coll=ACM&amp;dl=ACM&amp;CFID=#{current_member.session_id}&amp;CFTOKEN=#{current_member.session_token}"
      else
        "http://portal.acm.org/results.cfm?coll=ACM&amp;dl=ACM"
      end
    end
    
    def image_thumbnail_for_article_summary(article, url)
      feed = article.feed
      
      if article.image
        if File.exist?(RAILS_ROOT + "/public" + article.image.public_filename(:small).split("?").first)
          "<a href=\"#{url}\"><img src=\"#{h(article.image.public_filename(:small))}\" alt=\"#{h(article.title)}\" class=\"pic\" /></a>"
        elsif File.exist?(RAILS_ROOT + "/public" + article.image.public_filename(:small_square).split("?").first)
          "<a href=\"#{url}\"><img src=\"#{h(article.image.public_filename(:small_square))}\" alt=\"#{h(article.title)}\" class=\"pic\" /></a>"
        end
      elsif feed && feed.is_a?(RssFeed) && feed.feed_type.name.eql?("Blog") && feed.default_article_image
        if File.exist?(RAILS_ROOT + "/public" + feed.default_article_image.public_filename(:small).split("?").first)
          "<a href=\"#{url}\"><img src=\"#{h(feed.default_article_image.public_filename(:small))}\" alt=\"#{h(article.title)}\" class=\"pic\" /></a>"
        elsif File.exist?(RAILS_ROOT + "/public" + article.feed.default_article_image.public_filename(:small_square).split("?").first)
          "<a href=\"#{url}\"><img src=\"#{h(feed.default_article_image.public_filename(:small_square))}\" alt=\"#{h(article.title)}\" class=\"pic\" /></a>"
        end
      end
    end

    desc %{ 
      Renders the containing elements if all of the listed parts exist on a page and are not empty.
      By default the @part@ attribute is set to @body@, but you may list more than one
      part by separating them with a comma. Setting the optional @inherit@ to true will 
      search ancestors independently for each part. By default @inherit@ is set to @false@.

      When listing more than one part, you may optionally set the @find@ attribute to @any@
      so that it will render the containing elements if any of the listed parts are found.
      By default the @find@ attribute is set to @all@.

      *Usage:*
      <pre><code><r:if_content [part="part_name, other_part"] [inherit="true"] [find="any"]>...</r:if_content></code></pre>
    }
    tag 'if_part_has_content' do |tag|
      page = tag.locals.page
      part_name = tag_part_name(tag)
      parts_arr = part_name.split(',')
      inherit = boolean_attr_or_error(tag, 'inherit', 'false')
      find = attr_or_error(tag, :attribute_name => 'find', :default => 'all', :values => 'any, all')
      expandable = true
      one_found = false
      part_page = page
      parts_arr.each do |name|
        name.strip!
        if inherit
          while (part_page.part(name).nil? and (not part_page.parent.nil?)) do
            part_page = part_page.parent
          end
        end
        expandable = false if part_page.part(name).content.blank?
        one_found ||= true if !part_page.part(name).content.blank?
      end
      expandable = true if (find == 'any' and one_found)
      tag.expand if expandable
    end

    desc %{
      The opposite of the @if_content@ tag. It renders the contained elements if all of the 
      specified parts do not exist or contain content. Setting the optional @inherit@ to true will search 
      ancestors independently for each part. By default @inherit@ is set to @false@.

      When listing more than one part, you may optionally set the @find@ attribute to @any@
      so that it will not render the containing elements if any of the listed parts are found.
      By default the @find@ attribute is set to @all@.

      *Usage:*
      <pre><code><r:unless_content [part="part_name, other_part"] [inherit="false"] [find="any"]>...</r:unless_content></code></pre>
    }
    tag 'unless_part_has_content' do |tag|
      page = tag.locals.page
      part_name = tag_part_name(tag)
      parts_arr = part_name.split(',')
      inherit = boolean_attr_or_error(tag, 'inherit', false)
      find = attr_or_error(tag, :attribute_name => 'find', :default => 'all', :values => 'any, all')
      expandable, all_found = true, true
      part_page = page
      parts_arr.each do |name|
        name.strip!
        if inherit
          while (part_page.part(name).nil? and (not part_page.parent.nil?)) do
            part_page = part_page.parent
          end
        end
        expandable = false if !part_page.part(name).content.blank?
        all_found = false if part_page.part(name).content.blank?
      end
      if all_found == false and find == 'all'
        expandable = true
      end
      tag.expand if expandable
    end

    
  end
end