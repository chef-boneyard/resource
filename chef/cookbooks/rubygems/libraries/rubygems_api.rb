unless self.class.const_defined?(:RubygemsAPI)

require 'rubygems/command'
require 'rubygems/gemcutter_utilities'
require 'json'

class RubygemsAPI
  include Gem::GemcutterUtilities

  def initialize(host: nil, allowed_push_host: nil, api_key: nil)
    self.host = host if host
    @allowed_push_host = allowed_push_host if allowed_push_host
    @api_key = api_key if api_key
  end

  attr_reader :allowed_push_host
  attr_reader :api_key

  def request(method, path, log, params: nil)
    uri = host + path
    if method == :get
      log.debug("Hitting #{method.to_s.upcase} #{uri}.")
    else
      log.info("Hitting #{method.to_s.upcase} #{uri}.  API key: #{api_key}")
    end
    begin
      response = rubygems_api_request(method, path, host, allowed_push_host) do |request|
        request.add_field("Authorization", api_key) if api_key
        if params
          params = params.inject({}) { |h,(key,value)| h[key.to_s] = value.to_s; h }
          log.debug("Form parameters: #{params.map { |key,value| "#{key}=#{value}" }.join(', ')}")
          request.set_form_data(params)
        end
      end
      response.value
    rescue Net::HTTPExceptions => e
      log.error("Failed to #{method} #{uri}: #{response}.  Body:")
      log.debug(response.body)
      # Create an actually INTELLIGIBLE error message.
      new_exception = e.class.new("#{$!.message} from #{method.to_s.upcase} #{uri}", e.response)
      new_exception.set_backtrace(e.backtrace)
      raise new_exception
    end
    log.debug("Successfully hit #{method} #{uri}. Body:")
    log.debug(response.body)
    response.body
  end

  def get_raw(path, log, **params)
    # Add query parameters (GET does not do form post)
    if params && !params.empty?
      path = "#{path}?#{params.map { |k,v| "#{CGI.escape(k)}=#{CGI.escape(v)}" }.join(';')}"
    end
    request(:get, path, log)
  end

  def get(path, log, **params)
    JSON.parse(get_raw(path, log, **params))
  end

  def put(path, log, **params)
    request(:put, path, log, params: params)
  end

  def post(path, log, **params)
    request(:post, path, log, params: params)
  end

  def delete(path, log, **params)
    request(:delete, path, log, params: params)
  end
end

end
