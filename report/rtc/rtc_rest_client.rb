# RTC Rest client
# This client fires API calls to the customized RTC client REST interfaces hosted on a web server
# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-Jul-13

class RTCRestClient
  attr_accessor :rest_type, :api, :params, :payload
  attr_reader :status_code, :response_body, :run_successfully

  def initialize(rest_type, api, params, payload)
    @rest_type = rest_type
    @api = api
    @params = Hash.new
    @params['params'] = params  # to be passed into the header hash for rest-client gem
    @payload = payload
    @status_code = nil
    @response_body = nil
    @run_successfully = nil
  end

  def run_api
    response = case @rest_type
                 when :get
                   @api.get(@params)
                 when :put
                   @api.put(@params, @payload)
                 when :post
                   @api.post(@params, @payload)
                 when :delete
                   @api.delete(@params)
                 else
                   raise "Invalid REST type #{@rest_type} received. Accept get, put, post and delete only."
               end
    @status_code = @api.get_response_code response
    @response_body = @api.get_response_body_as_hash response
    @run_successfully = @api.ran_successfully? response
  end

end