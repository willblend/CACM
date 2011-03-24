module ContentTypes::Helper

  def content_type_part_field(content_type_part, index)
    part_content = @page.part(content_type_part.name).content rescue ''
    
    field_name = "part[#{index}][content]"
    field_id = "part_#{index}_content"

    options = {:class => content_type_part.part_type.field_class, 
               :style => content_type_part.part_type.field_styles,
               :id => field_id}.reject{ |k,v| v.blank? }

    field_html = []

    case content_type_part.part_type.field_type
      when "text_area"
        field_html << @template.text_area_tag(field_name, h(part_content), options.merge( :cols => '60', :rows => '20' ))

      when "text_field"
        field_html << @template.text_field_tag(field_name, h(part_content), options)

      when "check_box"
        field_html << @template.check_box_tag(field_name, "true", part_content =~ /true/, options)
        field_html << @template.hidden_field_tag(field_name, "false", :id => "part_#{index}_content_hidden")

      when "hidden"
        field_html << @template.hidden_field_tag(field_name, part_content, options)

      when "asset"
        unless part_content.blank?
          asset  = Asset.find_by_path(part_content) rescue part_content = ''
        end

        field_html << @template.text_field_tag(field_name + "_filename", asset.filename, :class => 'TextInput', :disabled => 'disabled', :id => "#{field_id}_filename") unless part_content.blank?
        field_html << @template.text_field_tag(field_name, part_content, options.merge( :class => 'asset-manager-field', :id => field_id))
        field_html << tag(:img, :src => asset.public_filename, :class => 'asset-manager-preview', :alt => '', :id => "#{field_id}_asset_preview") unless part_content.blank?
    end

    field_html.join("\n")
  end

end
