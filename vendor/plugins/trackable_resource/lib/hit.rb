class Hit < ActiveRecord::Base
  belongs_to :trackable, :polymorphic => true
  
  def request=(request)
    self.user_ip    = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referer   = request.env['HTTP_REFERER']
  end
end