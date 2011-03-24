module CACM
  module FullTextExtensions

    # Association Proxy Extension between Articles and associated FullTexts
    CACM::NON_DL_FULL_TEXT_TYPES.each do |type|
      define_method type do
        find_by_type type.gsub(/_/, ' ')
      end
    end

  end
end