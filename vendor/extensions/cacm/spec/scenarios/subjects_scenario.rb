class SubjectsScenario < Scenario::Base
  uses :articles_base

  def load

    create_record Subject, :artificial_intelligence, :name => "artificial intelligence"
    create_record Subject, :communications_networking, :name => "communications / networking"
    create_record Subject, :computer_applications, :name => "computer applications"
    create_record Subject, :computer_human_interactions, :name => "computer-human interactions"
    create_record Subject, :computers_and_society, :name => "computers and society"
    
    create_record Subject, :entertainment, :name => 'Entertainment'
    create_record Subject, :cats, :name => 'Cats'

    10.times do
      a = Article.new(valid_article)
      a.subjects << subjects(:entertainment)
      a.save
      a.approve!
      a.save
    end

    10.times do
      a = Article.create(valid_article)
      a.subjects << subjects(:cats)
      (rand(5)+1).times do
        a.comments << Comment.create(:comment => "Bleh, computing is fun")
      end
      a.comments.each { |x| x.approve! }
      a.save
      a.approve!
      a.save
    end
  end
  
end