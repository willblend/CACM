require 'spec/rake/spectask'

desc 'CruiseControl build task'
task :cruise do
  Rake::Task['db:migrate:extensions'].invoke
  Rake::Task['db:test:prepare'].invoke
  Rake::Task['radiant:extensions:update_all'].invoke
  Rake::Task['cruise:coverage'].invoke
end

namespace :cruise do

  desc "Run specs with rcov"
  task :coverage do
    Spec::Rake::SpecTask.new('cruise:coverage') do |t|
      t.spec_opts = ['--options', "#{RAILS_ROOT}/spec_rcov.opts"]
      t.spec_files = FileList['vendor/extensions/cacm/spec/**/*_spec.rb']
      t.rcov = true
      t.rcov_opts = ['--exclude', 'spec,/usr/lib/ruby,config', '--include-file', 'vendor/extensions/cacm/app,vendor/extensions/cacm/lib', '--sort', 'coverage']
      t.rcov_dir = ENV['CC_BUILD_ARTIFACTS']
    end
  end
  
end