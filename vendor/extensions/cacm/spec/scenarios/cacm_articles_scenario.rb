class CacmArticlesScenario < Scenario::Base
  uses :feeds, :issues

  def load
    create_cacm_article :cacm_article, :title => "Article Stub"
    create_cacm_article :super_computing, :title => "Super Computing"
    create_cacm_article :crystallography, :title => "Crystallography"
    create_cacm_article :zero_sum_games, :title => "Zero Sum Games"
    create_cacm_article :histone_acetylation, :title => "Histone Acetylation"
    CacmArticle.find(:all).each_with_index { |x,i| (i+1).times { Hit.create(:trackable_id => x.id, :trackable_type => x.class_name, :user_ip => "127.0.0.1", :user_agent => "rSpec fool") }}
  end

  StubArticle = Struct.new(:title, :author_names, :publication_date, :abstract, :doi, :citation_url, :issue, :ccs_terms, :sort_key, :full_texts, :publication_id, :subtitle)
  StubOracleArticle = Struct.new(:created_date)
  Wrap = Struct.new(:source)
  
  helpers do
    def article_stub
      StubArticle.new('Article Stub', 'Author Name', Date.today, 
                      'Lorem ipsum dolor', '1234567890', 'http://digitalpulp.com', 
                      issues(:december), [], IDGEN.next, nil, 'J79', 'Awesome')
    end

    def oracle_stub
      StubOracleArticle.new(Date.today)
    end

    def wrapped_oracle_stub
      Wrap.new(oracle_stub)
    end
  end

  private
  def base_cacm_article
    { :class_name => 'CacmArticle', :state => "approved", :feed_id => feeds(:cacm).id, :author => "Author Name",
      :short_description => "Lorem ipsum dolor", :issue_id => issues(:december).id, :full_text => "Lorem ipsum dolor", :subtitle => "Awesome" }
  end

  def create_cacm_article(name, props)
    create_record CacmArticle, name, base_cacm_article.merge(props)
  end  
end