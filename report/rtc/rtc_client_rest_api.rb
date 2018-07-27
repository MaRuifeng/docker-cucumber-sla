# Customized RTC client REST API
# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-Jul-12

# require './rtc_log'
require_relative '../report_log'

require 'rest-client'
require 'data_magic'
require 'json'
require 'find'
require_relative '../constants'

class RTCClientRestAPI
  include DataMagic

  # Load environment configuration data
  DataMagic.yml_directory = File.expand_path('../../', __FILE__)
  DataMagic.load('env_config.yml')

  attr_reader :url, :headers

  # Initialization
  def initialize (relative_url)
    @url = get_server + relative_url
    @headers = Hash.new
  end

  def get_server
    data_for(:RTC_client_api_url)[:RTC_client_server]
  end

  # def get_rest_url; raise 'SubclassResponsibility'; end

  def set_headers(headers)
    # rest-client gem: Due to unfortunate choices in the original API,
    # the params used to populate the query string need to be put into the headers hash.
    @headers[:accept] = 'application/json'
    @headers[:content_type] = 'application/json'
    headers.nil? ? () : @headers.merge!(headers)
  end

  # API calls
  def get(params)
    ReportLog.info('')
    ReportLog.info("==> GET request: #{@url}")
    ReportLog.info("==> Querying parameters: #{params.nil? ? '<no parameters>' : params.to_s}")
    response = RestClient::Request.new({
        method: :get,
        url: @url,
        headers: set_headers(params),
        timeout: nil
    }).execute do |response, request, result|
      # puts response.to_yaml.to_s
      # puts response.net_http_res.class
      # puts Net::HTTPOK
      # puts response.body.class
      ReportLog.info("==> Headers: #{@headers.nil? ? '<no headers>' : @headers.to_s}")
      ReportLog.info("<== Status code: #{response.code}")
      ReportLog.info("<== Response body: #{response.body}")
      ReportLog.info('')
      response
    end
    response
  end

  def put(params, payload)
    ReportLog.info('')
    ReportLog.info("==> PUT request: #{@url}")
    ReportLog.info("==> Querying parameters: #{params.nil? ? '<no parameters>' : params.to_s}")
    # ReportLog.info("==> Payload: #{payload.nil? ? '<no payload>' : payload.to_s}")
    response = RestClient::Request.new({
        method: :put,
        url: @url,
        payload: payload,
        headers: set_headers(params),
        timeout: nil
    }).execute do |response, request, result|
      ReportLog.info("==> Headers: #{@headers.nil? ? '<no headers>' : @headers.to_s}")
      ReportLog.info("<== Status code: #{response.code}")
      ReportLog.info("<== Response body: #{response.body}")
      ReportLog.info('')
      response
    end
    response
  end

  def post(params, payload)
    ReportLog.info('')
    ReportLog.info("==> POST request: #{@url}")
    ReportLog.info("==> Querying parameters: #{params.nil? ? '<no parameters>' : params.to_s}")
    response = RestClient::Request.new({
        method: :post,
        url: @url,
        payload: payload,
        headers: set_headers(params),
        timeout: nil
    }).execute do |response, request, result|
      ReportLog.info("==> Headers: #{@headers.nil? ? '<no headers>' : @headers.to_s}")
      ReportLog.info("<== Status code: #{response.code}")
      ReportLog.info("<== Response body: #{response.body}")
      ReportLog.info('')
      response
    end
    response
  end

  def delete(params)
    ReportLog.info('')
    ReportLog.info("==> DELETE request: #{@url}")
    ReportLog.info("==> Querying parameters: #{params.nil? ? '<no parameters>' : params.to_s}")
    response = RestClient::Request.new({
        method: :delete,
        url: @url,
        headers: set_headers(params),
        timeout: nil
    }).execute do |response, request, result|
      ReportLog.info("==> Headers: #{@headers.nil? ? '<no headers>' : @headers.to_s}")
      ReportLog.info("<== Status code: #{response.code}")
      ReportLog.info("<== Response body: #{response.body}")
      ReportLog.info('')
      response
    end
    response
  end

  # Processing responses
  def get_response_code(response)
    response.nil? ? raise('No API response received.') : response.code
  end

  def get_response_body_as_hash(response)
    response.nil? ? raise('No API response received.') : JSON.parse(response.body)
  end

  # Check if API call is successfully completed (status OK and no error message)
  def ran_successfully?(response)
    if response.nil?
      raise('No API response received.')
    elsif (response.net_http_res.is_a? Net::HTTPOK)
      (JSON.parse(response.body).has_key? Constants::JSON_KEY_ERROR_MSG) ? false : true
    else
      false
    end
  end

end