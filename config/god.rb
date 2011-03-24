# SAMPLE GOD.CONF HEADER

RAILS_ROOT = '/srv/rails/cacm/current'
SHARED_DIR = File.expand_path(File.join(RAILS_ROOT, %w(.. shared)))
God.pid_file_directory = File.join(SHARED_DIR, 'log')

God::Contacts::Email.message_settings = {
  :from => 'cacm-alerts@digitalpulp.com'
}

God::Contacts::Email.server_settings = {
  :address        => "mail.digitalpulp.com",
  :port           => 25,
  :domain         => "digitalpulp.com",
  :authentication => :plain,
  :user_name      => "development@digitalpulp.com",
  :password       => "s@uc3"
}

developers = ['cacm-alerts']
developers.each do |email|
  God.contact(:email) do |c|
    c.name  = email
    c.email = ( email =~ /@/ ? email : "#{email}@digitalpulp.com")
    c.group = 'developers'
  end
end

# IT IS VERY IMPORTANT THAT YOU EXPORT RAILS_ENV
# INTO THE REMOTE DEPLOY USER'S ENVIRONMENT --
# DO NOT RELY ON THIS LINE!!
ENV['RAILS_ENV'] ||= 'development'

# Load all files in config/recipes/*.god.rb
God.load File.join(RAILS_ROOT, %w(config recipes *.god.rb))