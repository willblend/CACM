ActionMailer::Base.logger = ActiveRecord::Base.logger
ActionMailer::Base.send(:include, ActionMailer::Mock)