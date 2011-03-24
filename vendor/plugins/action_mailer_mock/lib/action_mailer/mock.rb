module ActionMailer  
  module Mock
    
    def self.included(base)
      base.class_eval do
        base.alias_method_chain :deliver!, :mocking
        base.cattr_accessor :exception_address, :mock_address
      end
    end

    def deliver_with_mocking!(mail=@mail)
      if :mock == ActionMailer::Base.perform_deliveries
        unless [*mail.to].include?(ActionMailer::Base.exception_address)
          mail.subject = mail.to[0] + '||' + mail.subject
          mail.to      = ActionMailer::Base.mock_address
        end
        mail.cc = mail.bcc = []
      end
      deliver_without_mocking!(mail)
    end
     
  end
end