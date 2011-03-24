module CACM
  module SectionExtensions
    # This a has_many association extension between Oracle::Issue and Sections
    ['departments', 'sections', 'columns', 'special issues'].each do |type|
      define_method type do
        find_all_by_type type.singularize.upcase
      end
    end

  end
end