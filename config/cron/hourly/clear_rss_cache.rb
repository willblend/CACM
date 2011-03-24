#! /usr/bin/env ruby
require 'fileutils'
Dir['<%= current_path %>/public/**/*.rss'].each { |f| FileUtils.rm(f) }