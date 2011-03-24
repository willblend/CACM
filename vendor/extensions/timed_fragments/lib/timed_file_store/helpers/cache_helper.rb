# add options to standard ActionView cache helper
class TimedFileStore
  module Helpers
    module CacheHelper
      def self.included(base)
        base.class_eval do
          def cache(name = {}, options=nil, &block)
            @controller.cache_erb_fragment(block, name, options)
          end
        end
      end
    end
  end
end