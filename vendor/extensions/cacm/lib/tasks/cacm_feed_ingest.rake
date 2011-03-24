def puts_with_color(text, color_code)
  puts "#{color_code}#{text}\e[0m"
end

def puts_error(text);   puts_with_color(text, "\e[31m"); end
def puts_success(text); puts_with_color(text, "\e[32m"); end
def puts_warning(text); puts_with_color(text, "\e[33m"); end
def puts_note(text);    puts_with_color(text, "\e[34m"); end
def puts_query(text);   puts_with_color(text, "\e[35m"); end

namespace :cacm_feed do
  desc "RE Ingest Legacy CACM Articles"
  task(:reingest => :environment) do

    puts_note("Disabling TS")
    ThinkingSphinx.deltas_enabled = false
    
    save_failures = []
    full_texts_missing = []
    suspiciously_short = []

    batch_size = (ENV['batchsize']||1000).to_i
    puts_note("Set Batch Size: #{batch_size}")

    offset = (ENV['offset']||0).to_i
    puts_note("Set Offset: #{offset}")

    puts_note("Querying for local CACM Articles")
    CacmArticle.find(:all, :limit => batch_size, :conditions => "id > #{offset}", :order => :id).each do |article|

      if fulltext = article.fetch_dl_data
        puts_note("Full Text Found")

        if [10,9].include?(article.date.month) and article.date.year.eql?(2002)
          html = CacmArticle.parse_october_2002_html(Hpricot(fulltext[0]), fulltext[1])
        else
          html = article.extract_cacm_content(fulltext[0], fulltext[1])
        end
        article.full_text  = html[:full_text]
        article.leadin     = html[:leadin]
        article.toc        = html[:toc]
        
        if article.full_text.size < 1000
          suspiciously_short << article.id
        end
        
      else
        puts_warning("Full Text Not Found")
        full_texts_missing << article.id
      end

# KAS 02/11/2009 not needed for tonight's ingest as it was done already by JDF
# and keeping this here with test settings will overwrite a good link
#      article.link = Oracle::Article.find(article.oracle_id).citation_url

      if article.save
        puts_success("Article ##{article.id} Saved")
      else
        puts_error("Article ##{article.id} Save Failed!")
        save_failures << article.id
      end

    end

    puts_note("Task Complete. Errors will be displayed below.")
    
    unless full_texts_missing.empty?
      full_texts_missing.each do |missing|
        puts_warning("Full Text Missing, Article ID #{missing}")
      end
    end

    unless save_failures.empty?
      save_failures.each do |failure|
        puts_error("Save Failure, Article ID #{failure}")
      end
    end

    unless suspiciously_short.empty?
      suspiciously_short.each do |short|
        puts_error("Suspiciously Short, Article ID #{short}")
      end
    end

  end

  desc "Ingest Legacy CACM Articles"
  task(:regurgitate => :environment) do
    ThinkingSphinx.deltas_enabled = false

    batch_size  = (ENV['batchsize']||1000).to_i
    offset      = (ENV['offset']||0).to_i
    fails       = []

    session = Oracle::Session.new

    if session.authenticate_user(:user => CACM::ADMIN_USER, :passwd => CACM::ADMIN_PASS, :ip => '127.0.0.1')
      puts_success("Session Authenticated!")
    else
      puts session.inspect
      raise "Session Failed to Authenticate!"
    end

    articles = Oracle::Article.find(:all, :conditions => ["publication_id = ?", CACM::PUB_ID], :select => 'id', :order => 'publication_date DESC', :limit => batch_size, :offset => offset)

    puts "Selected #{articles.size} Articles with Offset #{offset}"

    articles.each_with_index do |article,index|
      begin
        local = CacmArticle.retrieve(article.id) do |art|
          art.feed_id = CACM::CACM_FEED_ID
          puts "Saving #{index+1} / #{batch_size}: #{art.title}"
        end
      rescue
        puts "Failed to Save: #{article.id}"
        fails << article.id
      ensure
        local = nil; GC.start
      end
      
      puts "\n"
      
    end

    puts_success("Batch Complete")

    unless fails.empty?
      puts "Failures Below:"
      fails.each do |failure|
        puts_error(failure)
      end
    end
  end
end