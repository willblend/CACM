class ArticlesBaseScenario < Scenario::Base
  uses :feeds, :feed_types

  helpers do
    def valid_article(opts={})
      i = IDGEN.next
      {:title => "title#{i}", :uuid => i, :state => "new", :full_text => 'Blah',
       :short_description => "Blah", :date => Time.now, :author => "Author Name",
       :feed_id => feeds(:cacm).id, :id => i}.merge(opts)
    end
  end
  
end