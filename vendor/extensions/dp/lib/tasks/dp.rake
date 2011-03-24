require 'rubygems'
require 'activerecord'

desc "Set the environment variable RAILS_ENV='staging'."
task :staging do
  ENV['RAILS_ENV'] = RAILS_ENV = 'staging'
  Rake::Task[:environment].invoke
end

desc "Set the environment variable RAILS_ENV='sandbox'."
task :sandbox do
  ENV['RAILS_ENV'] = RAILS_ENV = 'sandbox'
  Rake::Task[:environment].invoke
end

namespace :assets do
  desc "Backup /public/assets directory: rake assets:import outfile=assets.bz2"
  task :import do
    outfile = ENV['outfile']
    system "cd #{RAILS_ROOT}/public/system; tar xjvf #{outfile} assets"
  end
end

namespace :db do

  desc "Load a database connection without booting the environment"
  task :conn do
    opts = YAML.load_file('./config/database.yml')
    ActiveRecord::Base.establish_connection(opts[RAILS_ENV ||= 'development'])
  end

  namespace :sessions do
    desc "Clear old session data"
    task :expire => :conn do
      ActiveRecord::Base.connection.execute 'DELETE FROM sessions WHERE updated_at < NOW() - INTERVAL 1 DAY'
    end
  end

  desc "Import a .sql.bz2 file into the local database, and update the Sites setting.\nUsage: rake db:import bz2dumpfile=path/to/dumpfile.sql.bz2"
  task :import => :environment do
    bz2file = ENV['bz2dumpfile']
    config = HashWithIndifferentAccess.new do |hash,key|
      hash[key] = ActiveRecord::Base.connection.instance_variable_get(:@config)[key.to_sym]
    end

    db = config[:database]
    enc = config[:encoding]
    config[:password] &&= "-p#{config[:password]}"
    config[:host] &&= "-h#{config[:host]}"
    config[:username] &&= "-u #{config[:username]}"

    puts ">> Decompressing #{bz2file}."
    sqlfile = '/tmp/' + %x{cd /tmp && tar xjvf #{bz2file}}.chomp # %x{} captures output (unlike +system+)
    raise "Could not extract #{bz2file}" unless $?.success? # stop here on tar errors

    # multisite installed? then capture your old sites before we drop the database
    if ActiveRecord::Base.connection.tables.include?("sites")
      @sites = Site.find(:all)
    end

    puts ">> Dropping database #{config[:database]}."
    ActiveRecord::Base.connection.drop_database(config[:database])

    puts ">> Creating database #{config[:database]}."
    ActiveRecord::Base.connection.create_database(config[:database], {:encoding => config[:encoding]})

    puts ">> Importing #{sqlfile} into #{config[:database]}."
    # can't use AR::B connection to +SOURCE+ or +LOAD DATA+ from a dumpfile, have to do it manually
    system "mysql #{config[:host]} #{config[:username]} #{config[:password]} #{config[:database]} < #{sqlfile}"

    # multisite installed? then replace your old sites and report back if there is a row discrepancy
    Rake::Task["db:conn"].invoke #reestablish the connection before we check for the sites table again
    if ActiveRecord::Base.connection.tables.include?("sites")
      puts ">> Replacing your old site definitions"
      @imported_sites = Site.find(:all)

      @imported_sites.each do |site|
        old_site = @sites.select {|x| x.name.eql?(site.name)}.first
        if old_site
          site.update_attributes(old_site.clone.attributes)
        else
          puts ">> DP :: Warning :: New Site Created from Upstream Database"
        end
      end
    end

    puts ">> Cleaning up."
    system "rm #{sqlfile}"
  end
end