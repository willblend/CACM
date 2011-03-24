module CACM
  module ArchivesHelper

    def generate_index
      @issues = Issue.find(:all, :order => 'pub_date desc', :limit => 4, :conditions => ['state = (?)', 'approved'])
    end

    def generate_toc
      # ORACLE: Grab the sections for this issue
      @sections = @issue.sections

      # ORACLE: Grab the articles for this issue
      sources = @issue.articles.find(:all, :include => :section)
      fulltexts = Oracle::FullText.find(:all, :conditions => { :id => sources.map(&:id)} )

      # This goes through our local database and finds all the local ids
      locals = Article.find_all_by_oracle_id(sources.map(&:id)).compact
      # Start with an empty array for our article stash
      @articles = []

      # Iterate over the Oracle::Articles for this TOC we retrieved
      sources.each do |source|
        article = HashWithIndifferentAccess.new
        # After we build this array, it's fed to the archives/_article partial as
        # a collection. So for each in @articles, we have an article hash:

        # article[:oracle] = a reference to the Oracle::Article
        # article[:local] = a reference to the local CacmArticle
        # article[:full_texts] = array of article full texts
        # article[:full_text_types] = full_texts.collect(&:type), so we can skip the costly has_pdf?
        # article[:digital_edition_url] = the URL if it's in the digital library, nil if not.
        # article[:pages] = the page range, so we can skip the costly DLArticle.pages method later
        if local = locals.find { |l| l.oracle_id == source[:id].to_i }
          article[:oracle] = source
          article[:local] = local
          article[:full_texts] = fulltexts.select{ |f| f[:id] == source[:id] }
          article[:full_text_types] = article[:full_texts].collect(&:type)
          article[:digital_edition_url] = article[:full_text_types].include?("digital edition") ? article[:full_texts].select { |x| x.type.eql?("digital edition") }.first.url : nil
          article[:pages] = [source.start_page, source.end_page].uniq.compact
          @articles << article
        end
      end
    end

    def generate_year
      @issues = Oracle::Issue.year(params[:year]).reject {|x| x.local.nil? }.reject {|x| !x.local.approved? }
      raise ActiveRecord::RecordNotFound if @issues.blank?
    end

  end
end