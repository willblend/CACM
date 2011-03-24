module Enumerable
  def rcollect(&block)
    self.map do |item|
      collection = block.call(item).compact rescue []
      if collection && !collection.empty?
        [item, collection.rcollect(&block)]
      else
        item
      end
    end
  end
end

class Object
  def recurse_collecting(&block)
    [self, block.call(self).compact.rcollect(&block)]
  end
end