namespace :email_alerts do
  desc "Send out all email alerts."
  task(:email_alerts => :environment) do
    EmailAlerts.send_all
  end
end