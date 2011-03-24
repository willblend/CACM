class SectionsController < ArticlesController
  
  def syndicate
    @vertical = Section.find(params[:section])
    super
  end
  
  CACM::FULL_TEXT_TYPES.each do |method|
    define_method method do
      @vertical = Section.find(params[:section])
      super if validate_slug
    end
  end

end