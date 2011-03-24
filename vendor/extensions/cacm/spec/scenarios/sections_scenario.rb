class SectionsScenario < Scenario::Base
  uses :articles_base
  
  def load
    create_record Section, :news, :name => 'News', :position => 6
    create_record Section, :opinion, :name => 'Opinion', :position => 4
    create_record Section, :careers, :name => 'Careers', :position => 5
    create_record Section, :blogs, :name => 'Blogs'
    create_record Section, :blog_cacm, :name => 'Blog CACM', :position => 1, :parent_id => sections(:blogs).id
    create_record Section, :interviews, :name => 'Interviews', :position => 2, :parent_id => sections(:opinion).id
    create_record Section, :syndicated_blogs, :name => 'Syndicated Blogs', :position => 7, :parent_id => sections(:blogs).id
    
    10.times do
      a = Article.new(valid_article)
      a.sections << sections(:careers)
      (rand(5)+1).times do
        a.comments << Comment.create(:comment => "Bleh, computing is fun!")
      end
      a.comments.each { |x| x.approve! }
      a.save
      a.approve!
      a.save
    end
    
    10.times do
      a = Article.create(valid_article)
      a.sections << sections(:news)
      (rand(5)+1).times do
        a.comments << Comment.create(:comment => "Bleh, computing is fun")
      end
      a.comments.each { |x| x.approve! }
      a.save
      a.approve!
      a.save
    end
    
    10.times do
      a = Article.create(valid_article)
      a.sections << sections(:opinion)
      (rand(5)+1).times do
        a.comments << Comment.create(:comment => "Bleh, computing is fun! OPINIONED COMMNENT")
      end
      a.comments.each { |x| x.approve! }
      a.save
      a.approve!
      a.save
    end
    
    10.times do
      a = Article.create(valid_article)
      a.sections << sections(:blog_cacm)
      (rand(5)+1).times do
        a.comments << Comment.create(:comment => "Bleh, computing is fun! BLOGGING COMMENT")
      end
      a.comments.each { |x| x.approve! }
      a.save
      a.approve!
      a.save
    end
    
  end
  
end