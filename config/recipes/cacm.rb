Capistrano::Configuration.instance.load do
  namespace :cacm do
    before 'deploy', 'deploy:web:disable'
    before 'deploy:migrations', 'deploy:web:disable'
    
    after 'deploy', 'deploy:web:enable'
    after 'deploy:migrations', 'deploy:web:enable'
  end
end