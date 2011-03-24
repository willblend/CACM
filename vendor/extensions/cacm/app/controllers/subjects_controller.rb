class SubjectsController < ArticlesController
  
  def syndicate
    @vertical = Subject.find(params[:subject])
    super
  end

  CACM::FULL_TEXT_TYPES.each do |method|
    define_method method do
      @vertical = Subject.find(params[:subject])
      super if validate_slug
    end
  end

end