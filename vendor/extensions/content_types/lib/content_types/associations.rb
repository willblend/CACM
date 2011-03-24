module ContentTypes::Associations
  def self.included(base)
    base.class_eval {
      belongs_to :content_type
    }
  end
end
