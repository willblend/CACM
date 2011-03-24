namespace :cacm do
  desc "Identifies Oracle::Articles with Supplements from select non-CACM publications"
  task(:supplements => :environment) do

    Oracle::Article.find(:all, :conditions => ['publication_id IN (?)',["J882","J912","J190","J815","J582","J793"]], :select => 'id,citation_url', :order => 'publication_date DESC', :limit => 2000).each do |article|
      unless article.supplements.size.eql?(0)
        puts "Oracle::Article: #{article.id} | Supplements: #{article.supplements.size} | Citation URL: #{article.citation_url}"
      end
    end

  end

  desc "Identifies Oracle::Articles with non html/pdf fulltexts from the CACM publication"
  task(:fulltexts => :environment) do

    Oracle::Article.find(:all, :conditions => ['publication_id IN (?)',["J882","J912","J190","J815","J582","J793","J79"]], :select => 'id,citation_url', :order => 'publication_date DESC', :limit => 10000).each do |article|
      if article.full_texts.size > 2 && !article.full_texts.map(&:type).sort.eql?(["digital edition", "html", "pdf"])
        puts "Oracle::Article: #{article.id} | Full Texts: #{article.full_texts.size} | Citation URL: #{article.citation_url}"
      end
    end

  end
  
  desc "Finds relative links in all articles full texts"
  task(:find_relative_links => :environment) do
    
    Article.find(:all, :conditions => "full_text is not null", :select => "id,title,full_text").each do |article|
      
      dom = Hpricot(article.full_text)
      (dom/"a[@href]").each do |article_link|
        
        href = article_link.get_attribute(:href).lstrip
        
        unless href.starts_with("http") or href.starts_with("/") or href.starts_with("#") or href.starts_with("mailto:") or href.starts_with("javascript:") or href.include?("://")
          puts "Relative link in #{article.title} (#{article.id}):"
          puts article_link.to_html + "\n"
        end
        
      end
    end
  end
  
  desc "Find article figures+tables with multiple links"
  task(:find_double_figure_links => :environment) do
    
    bad_figures = []
    
    CacmArticle.find(:all, :conditions => "full_text is not null", :select => "id,title,full_text").each do |article|
      dom = Hpricot(article.full_text)
      (dom/"p.ThumbnailParagraph").each_with_index do |figure_or_table, index|
        if figure_or_table.search("a[@href]").length > 1
          bad_figures << article.id
          puts "Found multiple links in figure #{index} on #{article.title} (#{article.id})"
          puts figure_or_table.to_html + "\n\n"
        end
      end
    end
    
    puts "Found #{bad_figures.length} figures or tables with double links\n"
    puts "Name the guilty:\n#{bad_figures.uniq.join(', ')}"
    
    # Now if we want to fix these, call:
    # rake cacm:find_double_figure_links FIX=TRUE
    
    if ENV["FIX"].eql?("TRUE")
      bad_figures.uniq.each do |bad_article_id|
        
        article = CacmArticle.find(bad_article_id)
        if article and article.source
          if fulltext = article.fetch_dl_data

            if [10,9].include?(article.date.month) and article.date.year.eql?(2002)
              html = CacmArticle.parse_october_2002_html(Hpricot(fulltext[0]), fulltext[1])
            else
              html = article.extract_cacm_content(fulltext[0], fulltext[1])
            end
            article.full_text  = html[:full_text]
            article.leadin     = html[:leadin]
            article.toc        = html[:toc]
            
            if article.save
              puts "Article Saved: #{article.title} (#{article.id})"
            else
              puts "Article NOT SAVED!!! #{article.title} (#{article.id})"
            end
          end
        end
        
      end
    end
  end
  
  desc "Find 'back to top' links with incorrect class names and give them .totop"
  task(:fix_totop_class_names => :environment) do
    
    CacmArticle.find(:all, :conditions => "full_text is not null").each do |article|
      dom = Hpricot(article.full_text)
      modified = false
      (dom/".ThumbnailParagraph").each do |thumb_para|
        if thumb_para.inner_text.downcase.eql?("back to top")
          thumb_para.set_attribute :class, "totop"
          modified = true
        end
      end
      if modified
        article.full_text = dom.to_html
        if article.save
          puts "Saved! - #{article.title} (#{article.id})"
        else
          puts "\n\nNot Saved! - #{article.title} (#{article.id})\n\n"
        end
      end
    end
  end
  
  desc "Insert missing back to top links after figures and tables"
  task(:insert_top_anchors => :environment) do
    CacmArticle.find(:all, :conditions => "full_text is not null").each do |article|
      dom = Hpricot(article.full_text)
      modified = false
      
      # See comments in cacm_article.rb
      
      figures_div = dom.at("#article-figures")
      tables_div = dom.at("#article-tables")
      
      if figures_div
        unless figures_div.children_of_type("p").last.get_attribute(:class).eql?("totop")
          unless figures_div.next_sibling.name.eql?("p") and figures_div.next_sibling['class'].eql?("totop")
            figures_div.swap(figures_div.to_html + '<p class="totop"><a href="#PageTop">Back to top</a></p>')
            modified = true
          end
        end
      end
      
      if tables_div
        unless tables_div.children_of_type("p").last.get_attribute(:class).eql?("totop")
          unless tables_div.next_sibling.name.eql?("p") and tables_div.next_sibling['class'].eql?("totop")
            tables_div.swap(tables_div.to_html + '<p class="totop"><a href="#PageTop">Back to top</a></p>')
            modified = true
          end
        end
      end
      
      if modified
        article.full_text = dom.to_html
        if article.save
          puts "Saved! - #{article.title} (#{article.id})"
        else
          puts "\n\nNot Saved! - #{article.title} (#{article.id})\n\n"
        end
      end

    end
  end
  
  desc "Ingest CACM articles from Sep/Oct 2002"
  task(:ingest_fall_2002_articles => :environment) do
    
    CacmArticle.find(:all, :conditions => ['date between (?) and (?)', DateTime.civil(2002, 9, 1), DateTime.civil(2002, 10, 31)]).each do |article|
      
      if fulltext = article.fetch_dl_data
        # We already know the date range...
        html = CacmArticle.parse_october_2002_html(Hpricot(fulltext[0]), fulltext[1])
        article.full_text  = html[:full_text]
        article.toc        = html[:toc]
        
        # Deal with abstracts sanely...
        dom = Hpricot(article.full_text)
        paragraphs = (dom/"p")
        article.short_description = paragraphs.first.inner_text if paragraphs.first
        
      end
      
      if article.save
        puts "Saved :: #{article.title} (#{article.id})"
      else
        puts "Failed : #{article.title} (#{article.id})"
      end
      
    end
    
  end

  desc "Detect malformed chars in DB"
  task(:detect_malformed_chars => :environment) do

    # Article.find_all_by_id(18000..20000, :select => 'id,title').each do |article|
    #   unless (balsamic_reduction = article.title.gsub(/[\x00-\x7F ]+/, '')).blank?
    #     puts "ID: #{article.id}"
    #     puts "Title: #{article.title}"
    #     puts "Balsamic: #{balsamic_reduction}"
    #     puts "Unpacked: #{balsamic_reduction.unpack('U*').inspect}"
    #   end
    # end.size

    NORMAL_REGEX       = /[\x00-\x7F]/ # should be \x20-\x7F
    CTRL_CODES_REGEX   = /[\x00-\x1F]/
    WIN1252_REGEX      = /[\x80-\x9F]/
    EIGHT_BIT_CHARS_REGEX = /[^\x00-\x7F]/
    COMMON_CHARS       = [146, 150, 151, 160, 174, 8211, 8212, 8216, 8217, 8220, 8221, 8230, 8243, 8482]

    fields = %w(title author short_description full_text keyword description)

    report = {}
    Feed.find(:all).map(&:id).uniq.each do |f|
      report[f.to_s] = []
    end

    Article.find(:all, :select => (fields+["id", 'feed_id']).join(",")).each do |article|
      output = []

      fields.each do |prop|
        text = article.send(prop)
        next if text.nil?
        result = text.gsub(NORMAL_REGEX, '').scan(/./).uniq.to_s
        test = result.unpack('U*')
        # test = result.unpack('U*') - COMMON_CHARS

        unless test.empty?
          str = "   #{prop}: #{result} (#{result.unpack('U*').join(", ")})"
          str += "  --   #{text}" unless ["full_text", "short_description"].include?(prop)
          output << str
          if ["full_text", "short_description"].include?(prop)
            text.each_line do |l|
              output << l if EIGHT_BIT_CHARS_REGEX.match(l)
            end
          end
        end
      end

      unless output.empty?
        # there's one article w/o a feed id
        if article.feed_id.nil?
          print "\n"
          puts ">> #{article.id}: #{article.title}"
          puts output.join("\n")
          puts <<  "-"*78
        else
          print "."
          key = article.feed.id.to_s
          report[key] <<  "-"*78
          report[key] << ">> #{article.id}: #{article.title}"
          report[key] <<  output.join("\n")
        end
      end
    end

    print "\n"

    report.each do |key,data|
      next if data.empty?
      feed = Feed.find(key.to_i)
      File.open("bad_chars.#{feed.name.parameterize}.txt", "w+") do |f|
        puts ">> writing report for: #{feed.name}"
        f << feed.name + "\n"
        f << feed.feedurl + "\n" unless feed.feedurl.blank?
        f << data.join("\n")
      end
    end

  end
  
  desc "Decode html entities in article title/author"
  task(:decode_titles_and_authors => :environment) do
    
    ThinkingSphinx.deltas_enabled = false
    entity_handler = HTMLEntities.new
    
    Article.find(:all).each do |article|
      
      article.title = entity_handler.decode(article.title)
      article.author = entity_handler.decode(article.author)
      
      if article.save
        puts "Decoded and saved #{article.id}!"
      else
        puts ">>>>>>>>>>>>>> COULD NOT SAVE #{article.id}!!! <<<<<<<<<<<<<"
      end
      
    end
    
  end
  
  desc "Imports article subtitles from Oracle"
  task(:fetch_article_subtitles => :environment) do
    ThinkingSphinx.deltas_enabled = false
    DLArticle.find(:all).each do |dl_article|
      if source = dl_article.source
        if source.subtitle
          dl_article.subtitle = source.subtitle.strip 
          if dl_article.save
            puts "Saved article #{dl_article.id}"
          else
            puts "!!!!!! COULD NOT SAVE #{dl_article.id}  !!!!!!!"
          end
        end
      end
    end
  end
  
end