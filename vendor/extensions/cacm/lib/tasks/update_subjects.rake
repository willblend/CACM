namespace :update_subjects do
  desc "Update subjects as per ticket 518"
  task(:update => :environment) do
    ThinkingSphinx.deltas_enabled = false
    
    # ==== merge data storage and retrieval & data ====
    # 1. move all data storage and retrieval articles to 'data'
    Subject.find_by_name("data storage and retrieval").articles.each do |a|
      a.subjects << Subject.find_by_name("data") unless a.subjects.find_by_name("data")
      
      # remove the association
      a.subjects.delete(a.subjects.find_by_name("data storage and retrieval"))
    end
    
    # 2. remove 'data storage and retrieval'
    s = Subject.find_by_name("data storage and retrieval")
    if s.articles.length > 0
      print("***some articles are still assigned to data storage and retrieval! multiple assignments?\n")
    else
      s.destroy
    end
    
    # 3. rename 'data' to 'Data / Storage and Retrieval'
    s = Subject.find_by_name("data")
    s.name = "data / storage and retrieval"
    s.save
    
    # ==== merge robotics & AI ====
    # 1. move all robotics articles to AI
    Subject.find_by_name("robotics").articles.each do |a|
      a.subjects << Subject.find_by_name("artificial intelligence") unless a.subjects.find_by_name("artificial intelligence")
      
      # remove the association
      a.subjects.delete(a.subjects.find_by_name("robotics"))
    end
    
    # 2. remove 'data storage and retrieval'
    s = Subject.find_by_name("robotics")
    if s.articles.length > 0
      print("***some articles are still assigned to robotics! multiple assignments?\n")
    else
      s.destroy
    end
    
    # === get rid of e-commerce ===
    Subject.find_by_name("e-commerce").articles.each do |a|
      if a.subjects.count == 1
        print("Article ID #{a.id} (#{a.title}) only assigned to e-commerce section; needs reassignment.\n")
      else
        a.subjects.delete(a.subjects.find_by_name("e-commerce"))
      end
    end

    s = Subject.find_by_name("e-commerce")
    if s.articles.length > 0
      print("***some articles are still assigned to e-commerce! multiple assignments?\n")
    else
      s.destroy
    end

    Rake::Task['ts:in'].invoke
  end
end