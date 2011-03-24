namespace :radiant do
  namespace :extensions do
    namespace :timed_fragments do

      task :migrate => :environment
      task :update => :environment

    end
  end
end
