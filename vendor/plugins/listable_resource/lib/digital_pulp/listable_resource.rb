module DigitalPulp    
  module ListableResource
    
    class ListableResourceError < StandardError; end
    
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      attr_reader :sortable_fields
      def listable_resource(options = {})
        attributes = self.column_names rescue []
        
        @searchable_fields      = options[:searchable_fields]       || attributes
        
        cattr_accessor :filter_field
        self.filter_field       = options[:filter_field]            || nil
        
        cattr_accessor :index_search_field
        self.index_search_field = options[:index_search_field]      || nil
        
        @use_sorting            = options.delete(:use_sorting)      || true
        @sortable_fields        = options[:sortable_fields]         || attributes
        @default_sort_field     = options[:default_sort_field]      || nil
        @default_sort_direction = options[:default_sort_direction]  || 'asc'
      
      
        include DigitalPulp::ListableResource::InstanceMethods
        extend DigitalPulp::ListableResource::SingletonMethods
      end        
    end
    
    module InstanceMethods
      
      def matches_index(letter, matchcase=false)
        return false if index_search_field.nil?
        value = self.send(index_search_field.intern)
        return false if value.nil?
        if matchcase
          return value[0..0] == letter
        else
          return value[0..0].downcase == letter.downcase
        end
      end
      
    end
    
    module SingletonMethods
      
      def find_active_indexes(options={})
        raise ListableResourceError.new("Must define index_search_field in order to find by index") if index_search_field.nil?
        options.delete(:select)
        options[:select] = index_search_field
        resources = find(:all, options)
        active_indexes(resources)
      end
      
      def active_indexes(resources, matchcase=false)
        return [] if index_search_field.nil?
        resources.collect do |resource| 
          value = resource.send(index_search_field)[0..0]
          if matchcase
            value
          else
            value.to_s.downcase
          end
        end.uniq
      end
      
      def order_for(field)
        if field == @sort_field
          field + ' ' + reverse_sort_direction
        else
          field + ' ' + @default_sort_direction
        end
      end
      
      def find(*args)
        prepare_listable_resource_for_find_or_count(:find, args)
        super(*args)
      end
      
      def count(*args)
        prepare_listable_resource_for_find_or_count(:find, args)
        super(*args)
      end
      
      def prepare_listable_resource_for_find_or_count(action, args)
        options = defined?(args.extract_options!) ? args.extract_options! : extract_options_from_args!(args)
        prepare_conditions_for_listable_resource(options)
        options[:conditions] = listable_resource_conditions(options)
        options[:order] = listable_resource_order(options) if @use_sorting
        args.push(options)
      end
      
      def prepare_conditions_for_listable_resource(options)
        # IF: conditions have been pasted as a string
        # add condition to condition_statement
        # ELSE: split the conditions array into statement/args
        conditions = options.delete(:conditions)
        if conditions.is_a?(String)
          @condition_statement = [conditions]
          @condition_args = []
        elsif conditions.is_a?(Array)
          @condition_statement = [conditions.shift]
          @condition_args = conditions
        else
          @condition_statement = []
          @condition_args = []
        end
      end
      
      def listable_resource_order(options)
        order = options.delete(:order)
        order_field_and_direction(order)
      end
      
      def listable_resource_conditions(options)
        term    = options.delete(:search)
        index   = options.delete(:index)
        filter  = options.delete(:filter)
        
        search_conditions(term)  
        
        unless filter.blank?
          if filter_field.blank?
            raise ListableResourceError.new("Must define filter_field in order to find by filter")
          else
            filter_conditions(filter)  
          end
        end
        
        unless index.blank?
          if index_search_field.blank?
            raise ListableResourceError.new("Must define index_search_field in order to find by index")
          else
            index_conditions(index)
          end
        end
        
        @condition_statement.blank? ? nil : @condition_args.unshift(@condition_statement.join(" AND "))
      end      
      
      protected
      
      def order_field_and_direction(order)
        @sort_field = order.to_s.gsub(/\ (asc|desc)$/, '').strip
        @sort_direction = $1 || @default_sort_direction          
        @sortable_fields.include?(@sort_field) ? order : (@default_sort_field.blank? ? nil : "#{@default_sort_field} #{@default_sort_direction}")
      end
      
      def reverse_sort_direction
        @reverse_sort_direction = (@sort_direction == 'asc') ? 'desc' : 'asc'
      end
      
      def search_conditions(term)
        unless term.blank?
          search_condition_statement = []
          @searchable_fields.each do |field|
            if term.match(/^\".*\"$/)
              field = field.match(/\./) ? field : "#{table_name}.#{field}"
              search_condition_statement << "#{field} LIKE ?"
              @condition_args << "%#{term[1..-2]}%"  
            else
              terms = term.split(/\s+/)
              terms.each do |t|
                field = field.match(/\./) ? field : "#{table_name}.#{field}"
                search_condition_statement << "#{field} LIKE ?"
                @condition_args << "%#{t}%"
              end
            end
            
          end
          @condition_statement << " ( #{search_condition_statement.join(" OR ")} ) "              
        end
      end
      
      def filter_conditions(filter)
        unless filter.blank?
          filter_condition_statement = []
          unless filter.nil?
            filter_condition_statement << "#{filter_field} = ?"
            @condition_args << filter
          end
          @condition_statement << " ( #{filter_condition_statement.join(" AND ")} ) "
        end
      end
      
      def index_conditions(term)
        unless term.blank?      
          index_condition_statement = []       
          first_letter = term[0..0]
          if first_letter =~ /^[^a-z]$/i
            ("a".."z").map do |char|
              index_condition_statement << "LOWER(#{index_search_field}) NOT LIKE ?"
              @condition_args << "#{char}%"
            end
          elsif first_letter =~ /^[a-z]$/i
            index_condition_statement << "LOWER(#{index_search_field}) LIKE ?"
            @condition_args << "#{first_letter.downcase}%"
          else
            return false
          end
          @condition_statement << " ( #{index_condition_statement.join(" OR ")} ) "
        end          
      end
      
      
    end
    
  end
end