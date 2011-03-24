namespace :test_content do
  desc "Identify all test content in the system"
  task(:identify => :environment) do
    
    r = Regexp.new(/(TEST|TK|CHANGE_ME)/i)
    
    print("Searching Comments for test content...\n")        
    Comment.find(:all).each do |c|
      if c.comment =~ r
        print("#{c.id} - #{c.comment}\n")
      end
    end

    print("Searching Pages for test content...\n")        
    Page.find(:all).each do |c|
      if c.title =~ r
        print("#{c.id} - #{c.title}\n")
      end
    end


    print("Searching PageParts for test content...\n")        
    PagePart.find(:all).each do |c|
      if c.content =~ r
        print("#{c.id} - #{c.name}\n")
      end
    end

    print("Searching Widgets for test content...\n")        
    Widget.find(:all).each do |c|
      if c.content =~ r
        print("#{c.id} - #{c.name}\n")
      end
    end
    
    print("Searching Articles for test content...\n")        
    Article.find(:all).each do |c|
      if c.title =~ r || c.short_description =~ r #|| c.full_text =~ r
        print("#{c.id} - #{c.title}\n")
      end
    end
    
  end
  
  desc "Interactively purge test content"
  task(:purge => :environment) do
    r = Regexp.new(/\W(TEST|TK|CHANGE_ME)\W/i)
    
    print("Searching Comments for test content...\n")        
    Comment.find(:all).each do |c|
      if c.comment =~ r
        interactive_purge("#{c.id} - #{c.comment}", c)
      end
    end

    print("Searching Pages for test content...\n")        
    Page.find(:all).each do |c|
      if c.title =~ r
        interactive_purge("#{c.id} - #{c.title}\n", c)
      end
    end

    print("Searching PageParts for test content...\n")        
    PagePart.find(:all).each do |c|
      if c.content =~ r
        interactive_purge("#{c.id} - #{c.name}\n#{c.content}", c)
      end
    end

    print("Searching Widgets for test content...\n")        
    Widget.find(:all).each do |c|
      if c.content =~ r
        interactive_purge("#{c.id} - #{c.name}\n#{c.content}", c)
      end
    end    

    print("Searching Articles for test content...\n")        
    Article.find(:all).each do |c|
      if c.title =~ r || c.short_description =~ r #|| c.full_text =~ r
        interactive_purge("#{c.id} - #{c.title}", c)
      end
    end

  end
  
  def interactive_purge(prompt, ref)
    puts("\tpurge "+prompt+" ? (y/n)")
    resp = STDIN.gets.chomp

    if resp == 'y'
      ref.destroy
      puts("\t*** deleted #{ref.id} ***")
    end
  end
end