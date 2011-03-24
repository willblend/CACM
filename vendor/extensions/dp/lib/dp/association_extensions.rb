module DP
  module AssociationExtensions
    
    def self.included(base)
        base.alias_method_chain :method_missing, :associations
    end
  
    private
  
    ### Allows for HABTM-style get and set by array in simple HM:T relationships
    ###
    ### Usage:
    ### Class Foo < ActiveRecord::Base
    ###   include AssociationHelpers
    ###   has_many :foo_bars
    ###   has_many :bars, :through => :foo_bars
    ### end
    ###
    ### foo.bar_ids #=> [array, of, ids]
    ### foo.bar_ids=(array_of_ids) #=> clears bar_ids and associates rows listed in array
  
    def method_missing_with_associations(method_called, *args, &block)
      method_name = method_called.to_s
      args.flatten! ### fix problem with args == [[""]]
      case method_name
      when /^(\w+)_ids$/
        match = method_name.match /^(\w+)_ids$/
        reflection = match[1].to_s.pluralize
        instance_eval "#{reflection}.map &:id" if respond_to?(reflection)
        #instance_eval "#{reflection}.sort{|a,b| a.position <=> b.position}.map &:id" if respond_to?(reflection)
      when /^(\w+)_ids=$/
        match = method_name.match /^(\w+)_ids=$/
        reflection = match[1].to_s.pluralize
        if respond_to?(reflection)
          ids = (args || []).reject { |i| i.blank? }
          ids.map! { |i| i.to_i }
          ref = self.class.reflect_on_association(reflection.intern)
          join = ref.options[:through]
          instance_eval "#{join.to_s}.destroy_all"
          instance_eval "self.#{reflection} << #{ref.class_name}.find(ids)" unless ids.empty?
        end
      else
        method_missing_without_associations(method_called, *args, &block)
      end
    end
  
  end
end