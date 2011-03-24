module AssetManager
  module MassAnnouncements
    private
      def announce_nothing_uploaded
        flash[:error] = "Nothing was uploaded. Please select at least one file."
      end

      def announce_all_failed
        flash[:error] = "All of your uploads failed. Please try again. <p>#{failed_messages}</p>"
      end

      def announce_some_failed
        flash[:warning] = "These files failed to upload:<br /> #{failed_messages}<br /><br /> Your successful uploads are shown below."
      end

      def failed_messages
        @failed.reject { |f| f.filename.blank? }.map { |f| "<strong>#{f.filename}</strong> (#{f.errors.full_messages.to_sentence})." }.join("<br />")
      end

      def announce_multiple_updated
        flash[:notice] = "Metadata for multiple assets were saved."
      end
  end
end