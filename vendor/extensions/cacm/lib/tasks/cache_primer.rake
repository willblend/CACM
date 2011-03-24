# cache primer rake tasks.
# if you wanna brute force your way through the whole site, look at /script/crawler
# this is for crawling in a controlled, non-spidery manner
namespace :cache_primer do
  desc "hit all the TOCs"
  task(:tocs) do
    startyear = ENV['startyear'].blank? ? 1958 : ENV['startyear'].to_i
    endyear = ENV['endyear'].blank? ? Date.today.year : ENV['endyear'].to_i
    site = ENV['site'].blank? ? 'http://cacm.acm.org' : ENV['site']
    auth = ENV['auth'].nil? ? '' : '-u cacm:c0mput1n6'
    i = 0
    timeavg = 0
    
    starttime = Time.now
    (startyear..endyear).each do |year|
      (1..12).each do |month|
        startrequest = Time.now
        print "requesting #{site}/magazines/#{year}/#{month}...\n"
        system "curl #{site}/magazines/#{year}/#{month} #{auth} -o /dev/null\n"
        timeavg += Time.now - startrequest
        i += 1
      end
    end
    
    print "#{i} TOCs requested (#{(Time.now - starttime).round} sec; avg request speed = #{timeavg/i} sec)\n"
  end
  
  desc "hit a predefined list of pages"
  task(:from_list) do
    # curls a set of pages separated by line breaks from the infile
    if ENV['file'].blank?
      puts 'usage: \'rake cache_primer:from_list file=<filename> site=<site>\''
      exit 0
    end
    
    site = ENV['site'].blank? ? 'http://cacm.acm.org' : ENV['site']
    
    @file = File.new(ENV['file'], "r")

    starttime = Time.now
    i = 0
    timeavg = 0
    
    while (line=@file.gets)
      line.strip!
      startrequest = Time.now
      print "requesting #{site}#{line}\n"
      system "curl #{site}#{line} -o /dev/null\n"
      timeavg += Time.now - startrequest
      i += 1
    end
    print "#{i} pages requested (#{(Time.now - starttime).round} sec; avg request speed = #{timeavg/i} sec)\n"
    
    @file.close
    
  end
end