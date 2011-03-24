class CommentSweeper < ArticleSweeper
  # subclassed because the fragment-find logic is iffy and i don't
  # want it in two places -jdf
  
  observe Comment
  
  def after_save(record)
    if record.approved?
      article = record.commentable
      expire_record(article)
    end
  end
  
  def after_destroy(record)
    true # no-op
  end

end