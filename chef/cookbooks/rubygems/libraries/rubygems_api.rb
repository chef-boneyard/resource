unless self.class.const_defined?(:RubygemsAPI)

require 'rubygems/command'
require 'rubygems/gemcutter_utilities'

class RubygemsAPI
  include Gem::GemcutterUtilities

  def initialize(host: nil, allowed_push_host: nil, api_key: nil)
    self.host = host if host
    @allowed_push_host = allowed_push_host if allowed_push_host
    @api_key = api_key if api_key
  end

  attr_reader :allowed_push_host
  attr_reader :api_key

  def request(method, path, params: nil)
    result = rubygems_api_request(method, path, host, allowed_push_host) do |request|
      request.add_field("Authorization", api_key) if api_key
      if params
        params.inject({}) { |h,(key,value)| h[key.to_s] = value.to_s; h }
        request.set_form_data(params)
      end
    end
  end

  def get(path, **params)
    # Add query parameters (GET does not do form post)
    if params && !params.empty?
      path = "#{path}?#{params.map { |k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join(';')}"
    end
    request(:get, path)
  end

  def put(path, **params)
    request(:put, path, params: params)
  end

  def post(path, **params)
    request(:put, path, params: params)
  end

  def delete(path, **params)
    request(:delete, path, params: params)
  end
end

end