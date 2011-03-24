require 'net/https'

Capistrano::Configuration.instance.load do
  
  namespace :access do
    desc "Add a user's public key to the deploy account: cap {env} access:grant USER=josh"
    task :grant do
      key = keychain.get_key(ENV['USER'])
      unless key.nil? || key.empty?
        run "if grep '#{key}' ~/.ssh/authorized_keys ; then #{dp.whereis 'true'} ; else echo '#{key}' >> ~/.ssh/authorized_keys; fi"
      else
        logger.info "Failed: key was empty"
        false
      end
    end

    task :revoke do
      desc "Remove a user's public key from the deploy account: cap {env} access:revoke USER=josh"
      key = keychain.get_key(ENV['USER'])
      unless key.nil? || key.empty?
        run "awk 'index($0,\"#{key}\") == 0' ~/.ssh/authorized_keys > authorized_keys.tmp ; mv -f authorized_keys.tmp ~/.ssh/authorized_keys"
      else
        logger.info "Failed: key was empty"
        false
      end
    end
    
    task :setup do
      unless dp.file_exists? '~/.ssh/authorized_keys'
        run 'mkdir ~/.ssh'
        run 'touch ~/.ssh/authorized_keys'
        run 'chmod 700 ~/.ssh'
        run 'chmod 600 ~/.ssh/authorized_keys'
      end
    end
    before 'access:grant', 'access:setup'
    before 'access:revoke', 'access:setup'
  end
  
  module DigitalPulp
    module Keychain  
      def get_key(uname)
        dp.prompt(:passwd, "SVN password for #{user}")
        @user = uname
        @http = Net::HTTP.new('svn.digitalpulp.com', 443)
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        _,k = @http.start do |http|
          req = Net::HTTP::Get.new("/digitalpulp/public_keys/#{@user}")
          req.basic_auth 'deploy', passwd
          http.request(req)
        end
        return $1 if k.match(%r{^(.*)\s+#{@user}})
      end
    end
  end
  
  Capistrano.plugin :keychain, DigitalPulp::Keychain
  
end