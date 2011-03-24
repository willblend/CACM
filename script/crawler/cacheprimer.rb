# cache primer
# crawl the entire site in chunks as specified in crawl.txt
# change @host as you wish.

@linklint = "./linklint-2.3.5-dp" # our special sauce version of linklint that ignores robots.txt

@host = "cacm.acm.org"
@file = File.new("crawl.txt", "r")
taskstart = Time.now

while (line=@file.gets)
  starttime = Time.now
  outfolder = line.split("/")
  outfolder = outfolder[outfolder.length-2]
  system "mkdir out/#{outfolder}" rescue nil
  system "#{@linklint} -http -delay 1 -password CACM cacm:c0mput1n6 -host #{@host} #{line} -doc out/#{outfolder}/"
  print("CRAWLED #{line} (#{(Time.now - starttime).round} sec)\n")
end

print("SITE CRAWLING COMPLETE (#{(Time.now - taskstart).round} sec)\n")
@file.close