require 'action_mailer/ar_mailer'

class ArMailerExtension < Radiant::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/ar_mailer"
  
  def activate
#    ActionMailer::Base.class_eval do
      # allow ActionMailer::Base and ActionMailer::ARMailer to deliver via separate mechanisms
#      class_inheritable_accessor :delivery_method
#    end
#    ActionMailer::ARMailer.delivery_method = :activerecord
  end
  
  def deactivate
  end
  
end
