# defining in-block methods on a namespaced model fails under Rails 2.0.x

module CACM
  module CCSTermExtension
    def to_s
      map { |term| %Q("#{term.descr}") }.join(' ')
    end
  end
end