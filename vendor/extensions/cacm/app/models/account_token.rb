class AccountToken < ActiveRecord::Base
  before_save :make_token
  
  private
    def secure_digest(*args)
      Digest::SHA1.hexdigest(args.flatten.join('--'))
    end

    def make_token
      self.token = secure_digest(Time.now, (1..10).map{ rand.to_s }, self.email)
    end
end