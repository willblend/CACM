module CACM
  module CommentExtensions

    include CacmHelper

    # Inject the following behaviors into the Comment model of acts_as_commentable directly
    # Set the pagination default of per page, and introduce acts as state machine for CACM's 
    # comment moderation process. Use state machine and the before_destroy callback to keep 
    # the comments_count column on the Article model accurate
    #
    # Add first, last, and user name methods that uses the client_id column (Foreign Key) to 
    # look up the corresponding ACM Web Account and return the appropriate information where 
    # possible.
    #
    # Finally, add a callback to strip HTML before saving comments.
    #
    def self.included(base)
      base.class_eval do
        cattr_reader :per_page
        @@per_page = 10
        
        before_create :sanitize
        
        before_destroy do |comment|
          comment.commentable.class.decrement_counter(:comments_count, comment.commentable_id) if comment.commentable and comment.approved?
        end

        acts_as_state_machine :initial => :new

        state :new
        state :rejected
        state :approved,
          :enter => Proc.new { |comment|
            comment.commentable.class.increment_counter(:comments_count, comment.commentable_id) unless comment.commentable.nil?
          },
          :exit => Proc.new { |comment|
            comment.commentable.class.decrement_counter(:comments_count, comment.commentable_id) unless comment.commentable.nil?
          }

        event :reject do
          transitions :to => :rejected, :from => :new
          transitions :to => :rejected, :from => :approved
        end

        event :approve do
          transitions :to => :approved, :from => :new
          transitions :to => :approved, :from => :rejected
        end

      end
      
      def owner
        if self.client_id.nil?
          return "Anonymous"
        elsif self.name_first.blank? && self.name_last.blank?
          self.username
        else
          [self.name_first,self.name_last].compact.join(' ')
        end
      end
      
      def name_first
        @name_first ||= (account = Oracle::WebAccount.find(self.client_id)) ? account.name_first : ""
      end

      def name_last
        @name_last ||= (account = Oracle::WebAccount.find(self.client_id)) ? account.name_last : ""
      end

      def username
        @username ||= (account = Oracle::WebAccount.find(self.client_id)) ? account.username : "The account that made this comment no longer exists."
      end
      
      private
        # remove any tags from the comments before saving
        def sanitize
          self.comment = sanitizer.strip_tags(self.comment)
        end
      
    end

  end
end
