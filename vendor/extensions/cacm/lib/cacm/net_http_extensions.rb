module CACM
  module NetHttpExtensions
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      # like a regular Net::HTTP.get, but follows redirects (portal.acm.org -> delivery.acm.org, for instance)
      # Returns [body, location] so we can get the page plus its ultimate location.
      def get_with_redirects(url)
        html = { 'location' => url }
        10.times do
          location = html['location']
          html = get_response(URI.parse(location))
          return [html.body, location] if html.is_a?(Net::HTTPOK)
        end
        raise "Too many redirects while retrieving via GET (#{url})"
      end
      
      # Follow redirects but only send a HEAD. Returns response class (Net::HTTPOK, Net::HTTPClientError, etc).
      # Used for accounting requests.
      def head_with_redirects(url)
        url = URI.parse(url)
        10.times do
          start(url.host, url.port) do |http|
            resp = http.request_head([url.path, url.query].compact.join('?'), {'Connection' => 'close'})
            return resp.response unless resp.is_a?(Net::HTTPRedirection)
            url = URI.parse(resp['Location'])
          end
        end
        raise "Too many redirects while retrieving via HEAD (#{url})"
      end
    end

  end
end