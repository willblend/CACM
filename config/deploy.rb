#    SAMPLE DEPLOY.RB FOR RAILS AND RADIANT APPLICATIONS
#
#    GENERAL DEPLOY STRATEGY
# 
# 1) Define your environments:
#    In config/deploy/ you should have, or create,
#    a file per environment: staging.rb, production.rb, &c. Normally this file
#    only contains the domain for that server. E.g. staging.rb would contain:
#      set :domain, 'my-project.digitalpulp.com'
#
# 2) Set up the basic project structure on your remote server:
#    > cap {env} deploy:setup
#    (where {env} is one of staging, production, &c.) This creates the proper
#    directories for your rails app but does NOT check out any code.
#
# 3) Initialize database:
#    deploy:setup will prompt you to create a database. Do so. If this is a
#    fresh project, you might be able to get away with creating an empty DB
#    and running rake radiant:db:bootstrap. Under normal (read: imperfect)
#    conditions, this is a fine time to import a downstream database dump.
#
# 4) Run initial checkout:
#    > cap {env} deploy:cold
#    This checks out your source, makes all the appropriate symlinks, and
#    _very importantly_ provides a hook for other recipes to run their own
#    setup methods. Because it is run after the basic environment is
#    functional, this is an approproate place to run tasks which rely on
#    database connections (see: backup recipe).
#
#  5) Deploy further changes:
#     Now that everything is (hopefully) functional, further deploys can
#     be run with one of two cap tasks:
#     > cap {env} deploy
#     > cap {env} deploy:migrations

# Multi-stage support: for each environment, create a file in config/deploy
# (eg config/deploy/staging.rb, config/deploy/production.rb, &c) to hold
# environment-specific configuration. At a minimum, you should set the domain
# in each file: set :domain, 'appname.digitalpulp.com'
set :stages, %w(sandbox staging cache production)
require 'capistrano/ext/multistage'

# :application will be used to name common config files and file paths
set :application, "cacm"
set :repository,  "https://svn.digitalpulp.com/cacm/trunk/"

# /srv is the standard FHS path, should be used on RHEL/CentOS boxes
set :deploy_to, "/srv/rails/#{application}"
# Deploy via export so you're not putting .svn dirs in public realm
set :deploy_via, :export

# These are lazily evaluated based on the config/deploy/environments files
role(:app) { domain }
role(:web) { domain }
role(:db, :primary => true)  { domain }

# Run migrations in current environment
set(:rails_env) { stage }

# Standardize on a single deploy user to avoid permissions headaches.
# An overview of setting up a deploy user can be found here:
# https://wiki.digitalpulp.com/index.php/Ruby_on_Rails_Production
set :user, 'deploy'
set :runner, user
set :group, user

# The following needs to be set unless 'Defaults requiretty' is
# removed from /etc/sudoers on the remote host
default_run_options[:pty] = true

# This includes all recipe files in RAILS_ROOT/config/recipes. Each
# component (god, mongrel_cluster, ar_sendmail, &c) can maintain its
# own recipe file for easy mix-and-match on a per project basis.
Dir.new(File.join(File.dirname(__FILE__), 'recipes')).entries.sort.each do |entry|
  require "config/recipes/#{entry}" if entry =~ /\.rb$/ and entry !~ /\.god\.rb/
end

# declare Gem dependencies Run cap deploy:check to validate the 
# state of the remote server. Pass a simple symbol to verify any
# version is present; pass a hash of symbol => version to verify
# a specific release.

[:passenger, :rubyzip, :rspec, :backupgem, 'adzap-ar_mailer',
  {'ruby-oci8' => '1.0.3'}, 'activerecord-oracle_enhanced-adapter',
  'libxml-ruby', :rfeedparser, :curb].each do |gem|
  if gem.is_a?(Hash)
    name, version = gem.shift
    depend :remote, :gem, name, version
  else
    depend :remote, :gem, gem, '>=0'
  end
end