#--
# Copyright (C) 2006 Dimitrij Denissenko
# Please read LICENSE document for more information.
#++
require 'active_record'

module ActiveRecord #:nodoc:
  class Base

    class << self
  
      # This method works exactly the same way as the original with_scope 
      # method, but it applies globally and not just within a block.
      # Arguments:
      # 
      # * <b>reference_id</b> - ID reference to scope
      # * <b>method_scoping</b> - please see with_scope method documentation for further details 
      # * <b>options</b>:
      #   * <i>:override</i> - set this option to 'true' if you want to override an already existing global_scope (calling global_scope with the same reference_id twice leads to an exception otherwise)
      # 
      # Example:
      # 
      #   class Article < ActiveRecord::Base
      #     global_scope(:find_with_blog_id_one_only, :find => { :conditions => "blog_id = 1" })
      #     global_scope(:find_with_posts_and_limit, :find => { :conditions => "posts > 0", :limit => 1 })
      #     global_scope(:create_with_blog_id_one_by_default, :create => {:blog_id => 1})
      #   end
      #       
      #   Article.find(1)         # =>  SELECT * from articles 
      #                           #     WHERE blog_id = 1 AND posts > 0 AND id = 1 
      #                           #     LIMIT 1
      #   a = Article.create(2)   #
      #   a.blog_id               # =>  1
      #     
      # ATTENTION: This method is not meant to be used in a usual application
      # development process. General scopes are almost never a good idea, so 
      # please review your data and application structure before you try to 
      # implement it.
      def global_scope(reference_id, method_scoping = {}, options = {})
        if self.global_scope_hash.has_key?(reference_id) && !options[:override]
          raise  ActiveRecordError, "Global scope reference id '#{reference_id}' already exists!"
        end

        @@subclasses[self].each do |subclass|
          if !subclass.global_scope_hash.has_key?(reference_id) || options[:override]
            subclass.global_scope(reference_id, method_scoping, options)
          end
        end unless @@subclasses[self].blank?
        
        self.global_scope_hash[reference_id] = method_scoping;
      end

      # This method allows to skip a global scope directive. Example:
      # 
      #   class Article < ActiveRecord::Base
      #     global_scope(:find_with_blog_id_one_only, :find => { :conditions => "blog_id = 1" })
      #     global_scope(:find_with_author_id_one_only, :find => { :conditions => "author_id = 1" })
      #   end
      #     
      #   Article.find(:all)      # =>  SELECT * from articles WHERE blog_id = 1 AND author_id = 1
      #                           
      #   Article.without_global_scope(:find_with_blog_id_one_only) do 
      #     Article.find(:all)    # =>  SELECT * from articles WHERE author_id = 1
      #   end
      #     
      def without_global_scope(reference_id, &block)
        unless self.global_scope_hash.has_key?(reference_id)
          raise ActiveRecordError, "Invalid global scope: '#{reference_id}' for class '#{self.name}'. Defined global scopes: #{self.global_scope_hash.keys.inspect}"
        end

        method_scoping = self.global_scope_hash.delete(reference_id)
        begin
          yield
        ensure
          self.global_scope_hash[reference_id] = method_scoping;
        end      
      end

      # This is the original with_scope method with a small extension. :find parameters may now also include 
      # <tt>:order</tt> and <tt>:group</tt> options.
      # 
      # === Original documentation
      # 
      # Scope parameters to method calls within the block.  Takes a hash of method_name => parameters hash.
      # method_name may be :find or :create. :find parameters may include the <tt>:conditions</tt>, <tt>:joins</tt>,
      # <tt>:include</tt>, <tt>:offset</tt>, <tt>:limit</tt>, <tt>:order</tt>, <tt>:group</tt>, and <tt>:readonly</tt> options. :create parameters are an attributes hash.
      #
      #   Article.with_scope(:find => { :conditions => "blog_id = 1" }, :create => { :blog_id => 1 }) do
      #     Article.find(1) # => SELECT * from articles WHERE blog_id = 1 AND id = 1
      #     a = Article.create(1)
      #     a.blog_id # => 1
      #   end
      #
      # In nested scopings, all previous parameters are overwritten by inner rule
      # except :conditions in :find, that are merged as hash.
      #
      #   Article.with_scope(:find => { :conditions => "blog_id = 1", :limit => 1 }, :create => { :blog_id => 1 }) do
      #     Article.with_scope(:find => { :limit => 10})
      #       Article.find(:all) # => SELECT * from articles WHERE blog_id = 1 LIMIT 10
      #     end
      #     Article.with_scope(:find => { :conditions => "author_id = 3" })
      #       Article.find(:all) # => SELECT * from articles WHERE blog_id = 1 AND author_id = 3 LIMIT 1
      #     end
      #   end
      #
      # You can ignore any previous scopings by using <tt>with_exclusive_scope</tt> method.
      #
      #   Article.with_scope(:find => { :conditions => "blog_id = 1", :limit => 1 }) do
      #     Article.with_exclusive_scope(:find => { :limit => 10 })
      #       Article.find(:all) # => SELECT * from articles LIMIT 10
      #     end
      #   end
      def with_scope(method_scoping = {}, action = :merge, &block)
        method_scoping = preprocess_method_scoping(method_scoping)

        # Merge scopings
        if action == :merge && scoped_methods.last
          method_scoping = merge_method_scoping(scoped_methods.last, method_scoping)
        end
        self.scoped_methods << method_scoping

        begin
          yield
        ensure
          self.scoped_methods.pop
        end
      end
      
      protected
      
        def global_scope_hash#:nodoc:          
          write_inheritable_attribute(:global_scopes, {}) unless read_inheritable_attribute(:global_scopes)
          read_inheritable_attribute(:global_scopes)
        end

        def current_scoped_methods #:nodoc:
          current_scoped_methods = scoped_methods.last || {}

          global_scope_hash.values.each do |method_scoping|
            method_scoping = preprocess_method_scoping(method_scoping)          
            evaluate_proc_conditions!(method_scoping)
            current_scoped_methods = merge_method_scoping(current_scoped_methods, method_scoping)
          end
                    
          current_scoped_methods
        end             
      
              
      private  
          
        def evaluate_proc_conditions!(method_scoping)
          method_scoping.each_pair do |methods, params|
            params.each_pair do |key, value|
              method_scoping[methods][key] = value.call if value.is_a?(Proc)
            end
          end          
        end

        def preprocess_method_scoping(method_scoping) #:nodoc:
          method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

          # Dup first and second level of hash (method and params).
          method_scoping = method_scoping.inject({}) do |hash, (method, params)|
            hash[method] = (params == true) ? params : params.dup
            hash
          end
  
          method_scoping.assert_valid_keys([ :find, :create ])

          if f = method_scoping[:find]
	        f.assert_valid_keys([ :conditions, :joins, :select, :include, :from, :offset, :limit, :order, :readonly, :lock ])
            f[:readonly] = true if !f[:joins].blank? && !f.has_key?(:readonly)
          end
          
          method_scoping
        end

        
        def merge_method_scoping(original_scope, additional_scope) #:nodoc:
          original_scope.inject(additional_scope) do |hash, (method, params)|
            case hash[method]
              when Hash
                if method == :find
                  (hash[method].keys + params.keys).uniq.each do |key|
                    merge = hash[method][key] && params[key] # merge if both scopes have the same key
                    if key == :conditions && merge
                      hash[method][key] = [params[key], hash[method][key]].collect{ |sql| "( %s )" % sanitize_sql(sql) }.join(" AND ")
                    elsif key == :include && merge
                      hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                    else
                      hash[method][key] = hash[method][key] || params[key]
                    end
                  end
                else
                  hash[method] = params.merge(hash[method])
                end
              else
                hash[method] = params
            end
            hash
          end  
        end

    end
  end
end
