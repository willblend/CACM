namespace :this_day_in_history do
  desc "Populate the This Day In History model."
  task(:populate_database => :environment) do
    config = ActiveRecord::Base.configurations[RAILS_ENV]

    if ENV['sql'].nil?
      print "usage: rake this_day_in_history:populate_database sql=/path/to/filename\n"
      return 
    else
      file = ENV['sql']
    end

    # dump old table if it exists, load the new table, rename it
    ActiveRecord::Base.connection.execute("DROP TABLE this_day_in_histories") rescue nil
    system "mysql -u #{config['username']} -p#{config['password']} #{config['database']} < #{file}"
    ActiveRecord::Base.connection.execute("RENAME TABLE tdih2 TO this_day_in_histories") rescue nil
  end
  
  desc "Load the images for This Day In History and crop the thumbnails."
  task(:populate_images => :environment) do
    if ENV['images'].nil?
      print "usage: rake this_day_in_history:populate_images images=/path/to/images/\n"
      return
    else
      images = ENV['images']
    end

    # for each image
    images_in = Dir.open(images)
    IMAGES_HOME = RAILS_ROOT + "/vendor/extensions/cacm/public/images/tdih"
    imagesdir = Dir.open(IMAGES_HOME) rescue Dir.mkdir(IMAGES_HOME)
    thumbsdir = Dir.open(IMAGES_HOME + "/thumbs") rescue Dir.mkdir(IMAGES_HOME+"/thumbs")

    require 'RMagick'
    
    images_in.each { |i|
      # copy the file to the project dir and make thumbs.
      if !File.directory?(i) && [".jpg", ".gif", ".png"].include?(File.extname(i))
        File.copy(images_in.path + "/" + i, imagesdir.path)
        img = Magick::Image::read(images_in.path + "/" + i).first rescue print("*** unable to open image #{i}\n")
        if (img)
          thumb = img.resize_to_fill(100, 100, Magick::NorthGravity)
          thumb.write("#{thumbsdir.path}/#{i}")
        end
      end
    }
  end
end