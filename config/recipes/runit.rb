Capistrano::Configuration.instance.load do
  module DigitalPulp
    module CapUtil
      sv = '/usr/local/sbin/sv'

      # Set up runit configuration for a given daemon. Requires a .runit file
      # in $proj/shared which can be executed as a runit 'run' file.
      #
      # jdf 1/28/09 -- removed the portion of this task that initially wrote the
      # .runit into the shared dir. That file may have to come from a template 
      # (ar_sendmail.runit.erb or searchd.runit.erb for example.) The individual 
      # cap modules should be responsible for interpolating the template and
      # placing it in the shared path.
      def write_runit(daemon)
        svdt = '/usr/local/sbin/svdirtool'
        unless dp.file_exists?("/etc/sv/#{daemon}")
          run "chmod +x #{shared_path}/#{daemon}.runit"
          sudo "#{svdt} create #{daemon}"
          sudo "ln -nfs #{shared_path}/#{daemon}.runit /etc/sv/#{daemon}/run"
          sudo "#{svdt} link #{daemon}"
        end
      end

      # Start a service
      def start_runit(daemon)
        sudo "/usr/local/sbin/sv start #{daemon}"
      end

      # Stop a service
      def stop_runit(daemon)
        sudo "/usr/local/sbin/sv stop #{daemon}"
      end

      # Restart a service
      def restart_runit(daemon)
        sudo "/usr/local/sbin/sv restart #{daemon}"
      end

    end
  end
end