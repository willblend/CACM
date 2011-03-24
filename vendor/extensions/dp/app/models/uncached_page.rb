class UncachedPage < Page
  description %{
    Turn off caching for pages of this subclass
  }
  def cache?
    false
  end
end