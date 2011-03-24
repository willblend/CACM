module ContentTypesHelper
  def ruled_table_attributes
    {:id => "content_types", :class => "index", :cellspacing => "0", :cellpadding => "0", :border => "0"}
  end
  
  def content_types_css
    <<-CSS
        #content table.index .node .content_type a {  
          color: black; 
          text-decoration: none; 
        } 
        #content table.index .node .content_type { 
          font-size: 115%; font-weight: bold; 
        }
        .content_type_part {
          background: white;
        }
        .content_type_part label {
          display: none;
        }
    CSS
  end
  
  def content_types_scripts
    <<-JS
      var content_type_parts_index = 0;
      var content_type_part_partial = new Template(#{blank_content_type_part});
      function new_content_type_part(){
        var parts = $('parts');
        if(parts.down('.content_type_part')){
          var id = parts.select('.content_type_part').last().id;
          content_type_parts_index = parseInt(id.split("_").last());
        }
        content_type_parts_index += 1;
        new Insertion.Bottom('parts', content_type_part_partial.evaluate({index: content_type_parts_index}));
      }
      
      function fix_content_type_part_indexes(){
        var parts = $('parts');
        var new_index = 0;
        parts.select(".content_type_part").each(function(row){
          new_index += 1;
          row.select("input, select, textarea").each(function(input){
            input.name = input.name.sub(/\\d+/, new_index);
          });
        });
      }
      
      function reorder_content_type_part(element, direction){
        var parts = $('parts');
        var content_type_part = $(element).up('.content_type_part');
        switch(direction){
          case 'up':
            if(content_type_part.previous())
              content_type_part.previous().insert({ before: content_type_part });
            break;
          case 'down':
            if(content_type_part.next())
              content_type_part.next().insert({ after: content_type_part });
            break;
          case 'top':
            parts.insert({ top: content_type_part });
            break;
          case 'bottom':
            parts.insert({ bottom: content_type_part });
            break;
          default:
            break;
        }
        fix_content_type_part_indexes();
      }
    JS
  end
  
  def filter_options
    [['none', '']] + TextFilter.descendants.map { |f| f.filter_name }.sort
  end
  
  def part_type_options
    PartType.find(:all, :order => "name ASC").map {|t| [t.name, t.id]}
  end
  
  def blank_content_type_part
    ostruct = OpenStruct.new(:index => '#{index}')
    @blank_content_type_part ||= (render :partial => "content_type_part", :object => ostruct).to_json
  end
  
  def order_links(content_type)
    returning String.new do |output|
      %w{move_to_top move_higher move_lower move_to_bottom}.each do |action|
        output << link_to(image("#{action}.png", :alt => action.humanize), 
                          url_for(:action => action, :id => content_type), 
                          :method => :post)
      end
    end
  end
end
