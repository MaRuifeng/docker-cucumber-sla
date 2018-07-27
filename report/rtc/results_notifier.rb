# A messenger that retrieves build test results from the TEST DB
# and then sends notifications
# * Email through SMTP
# * Slack
# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-Aug-26

require 'net/smtp'
require_relative 'rtc_client_rest_api'
require_relative 'rtc_rest_client'


class ResultsNotifier

  @@class_name = self.name

  include DataMagic
  # Load environment configuration data
  DataMagic.yml_directory = File.expand_path('../../', __FILE__)
  DataMagic.load('env_config.yml')

  attr_accessor :test_category, :test_phase, :build_name

  def initialize(test_category, test_phase, build_name)
    @test_category = test_category
    @test_phase = test_phase
    @build_name = build_name
    @build_pass_rate = nil
    @build_test_results = nil
  end

  def post_to_slack
    ReportLog.entering(@@class_name, __method__.to_s)
    @build_pass_rate.nil? ? @build_pass_rate = get_build_pass_rate(@build_name, @test_category, @test_phase) : ()
    # Slack API
    url = data_for(:slack)[:incoming_webhook]
    input = Hash.new
    input[:attachments] = construct_slack_msg_attachments
    input[:channel] = data_for(:slack)[:channel]
    ReportLog.info('Posting build results to Slack...')
    ReportLog.info("==> POST request: #{url}")
    RestClient::Request.new({
                               method: :post,
                               url: url,
                               payload: JSON.generate(input),
                               headers: {:content_type => 'application/json'}
                           }).execute do |response, request, result|
      ReportLog.info("<== Status code: #{response.code}")
      ReportLog.info("<== Response body: #{response.body}")
    end
    ReportLog.info('Post to Slack completed.')
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  def send_email
    ReportLog.entering(@@class_name, __method__.to_s)
    @build_pass_rate.nil? ? @build_pass_rate = get_build_pass_rate(@build_name, @test_category, @test_phase) : ()
    recipient_list = get_recipient_list
    to_field=''
    recipient_list.each do |item|
      to_field = to_field + item + ','
    end
    # From and To headers in the message here doc are not used to route Emails
    message = <<MESSAGE_END
From: SDAD BPM Build <bpmbuild@sg.ibm.com>
To: #{to_field}
MIME-Version: 1.0
Content-type: text/html
Subject: SLA-UI Cucumber Test (#{@build_pass_rate['build_name']}) - #{get_percent(@build_pass_rate['pass_rate'])} passed

<style>
  h1, p {font-family:courier;}
</style>
<h1>Summary</h1>
<p>Test count: #{@build_pass_rate['test_count']}</p>
<p>Error count: #{@build_pass_rate['error_count']}</p>
<p>Failure count: #{@build_pass_rate['failure_count']}</p>
<p>Pass rate: <b style="color:blue">#{get_percent(@build_pass_rate['pass_rate'])}</b></p>
<p>RTC defect count: #{@build_pass_rate['defect_count'].to_json}</p>

<h1>Build</h1>
<p>Build: #{@build_pass_rate['build_name']}</p>
<p>Sprint: #{@build_pass_rate['sprint']}</p>
<p>Git branch: #{@build_pass_rate['git_branch']}</p>
<p>Build version: #{@build_pass_rate['build_version']}</p>

<a href="#{get_html_summary_url}" target="_blank">Report Details</a>
MESSAGE_END
    smtp_host = data_for(:smtp_server)[:host]
    smtp_port = data_for(:smtp_server)[:port]
    smtp_domain = 'localhost'
    smtp_user = data_for(:smtp_server)[:auth_user]
    smtp_pass = data_for(:smtp_server)[:password]
    smtp_from = data_for(:smtp_server)[:from_address]
    Net::SMTP.start(smtp_host, smtp_port, smtp_domain, smtp_user, smtp_pass, :plain) do |smtp|
      smtp.send_message(message, smtp_from, recipient_list)
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  def send_cucumber_error_email(error_msg)
    ReportLog.entering(@@class_name, __method__.to_s)
    recipient_list = get_recipient_list
    to_field=''
    recipient_list.each do |item|
      to_field = to_field + item + ','
    end
    # From and To headers in the message here doc are not used to route Emails
    message = <<MESSAGE_END
From: SDAD BPM Build <bpmbuild@sg.ibm.com>
To: #{to_field}
MIME-Version: 1.0
Content-type: text/html
Subject: SLA-UI Cucumber Test (#{@build_name}) - Failed to run

<style>
  h1, p {
         font-family: "Courier New", Courier, monospace;
         white-space: pre-wrap;
      }
</style>
<h1>Build</h1>
<pre>Build tag: #{@build_name}</pre>

<h1>Error Stack Trace</h1>
<pre style="color:red">#{error_msg}</pre>

MESSAGE_END
    smtp_host = data_for(:smtp_server)[:host]
    smtp_port = data_for(:smtp_server)[:port]
    smtp_domain = 'localhost'
    smtp_user = data_for(:smtp_server)[:auth_user]
    smtp_pass = data_for(:smtp_server)[:password]
    smtp_from = data_for(:smtp_server)[:from_address]
    Net::SMTP.start(smtp_host, smtp_port, smtp_domain, smtp_user, smtp_pass, :plain) do |smtp|
      smtp.send_message(message, smtp_from, recipient_list)
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  private

  # Get Email recipient list
  def get_recipient_list
    add_str = File.read("#{File.expand_path('../', __FILE__)}/email_recipients")
    recipient_list = Array.new
    add_str.split("\n").each do |add|
      if !add.nil? && add.match(/\A.+@.+\.com\Z/)
        recipient_list.push(add)
      end
    end
    return recipient_list
  end

  # Get summary report url
  def get_html_summary_url
    "http://#{data_for(:report_server)[:pub_ip]}#{data_for(:dir_config)[:result_directory].gsub("#{Dir.home}", '')}/summary.html"
  end

  # Get latest pass rate of the given build in given test category and test phase
  def get_build_pass_rate(build_name, test_category, test_phase)
    ReportLog.entering(@@class_name, __method__.to_s)
    build_pass_rate = Hash.new
    # set up RTC client
    api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_getBuildPassRates])
    params = Hash.new
    params[Constants::PARAM_TEST_CATEGORY] = test_category
    params[Constants::PARAM_TEST_PHASE] = test_phase
    params[Constants::PARAM_BUILD_NAME] = build_name
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_GET, api, params, nil)
    # run API
    ReportLog.info('Retrieving latest pass rate of the given build in given test category and test phase...')
    rtc_client.run_api
    if rtc_client.run_successfully
      ReportLog.info('All test results retrieved. Constructing build pass rate hash...')
      result_list = rtc_client.response_body.fetch(Constants::JSON_KEY_RESULT).fetch('Items')
      result_list.each do |result|
        build_pass_rate['defect_count'] = result['Defect Count']
        build_pass_rate['git_branch'] = result['Git Branch'].to_s
        build_pass_rate['sprint'] = result['Sprint'].to_s
        build_pass_rate['build_version'] = result['Build Version'].to_s
        build_pass_rate['build_name'] = result['Build Name'].to_s
        result['Pass Rates'].each do |pass_rate|
          build_pass_rate['test_count'] = pass_rate['Test Count']
          build_pass_rate['error_count'] = pass_rate['Error Count']
          build_pass_rate['failure_count'] = pass_rate['Failure Count']
          build_pass_rate['pass_rate'] = pass_rate['Pass Rate']
        end
      end
      ReportLog.info('Build pass rate hash constructed.')
    else
      raise construct_api_failure_msg(rtc_client)
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
    return build_pass_rate
  end

  # Get test result details of the given build in given test category and test phase
  def get_build_test_results(build_name, test_category, test_phase)
    ReportLog.entering(@@class_name, __method__.to_s)
    build_test_results = Array.new
    # set up RTC client
    api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_getBuildLatestTestResults])
    params = Hash.new
    params[Constants::PARAM_TEST_CATEGORY] = test_category
    params[Constants::PARAM_TEST_PHASE] = test_phase
    params[Constants::PARAM_BUILD_NAME] = build_name
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_GET, api, params, nil)
    # run API
    ReportLog.info('Retrieving latest test results of the given build in given test category and test phase...')
    rtc_client.run_api
    if rtc_client.run_successfully
      ReportLog.info('All latest test results retrieved. Constructing build test results hash...')
      result_list = rtc_client.response_body.fetch(Constants::JSON_KEY_RESULT).fetch('Items')
      result_list.each do |result|
        test_result = Hash.new
        unless result['Defect'].nil?
          test_result['defect_number'] = result['Defect']['Defect Number'].to_s
          test_result['defect_summary'] = result['Defect']['Defect Summary'].to_s
          test_result['defect_url'] = result['Defect']['Defect Link'].to_s
          test_result['defect_status'] = result['Defect']['Defect Status'].to_s
          test_result['defect_ts'] = result['Defect']['Defect Filed Timestamp'].to_s
        end
        test_result['test_count'] = result['Test Count']
        test_result['failure_count'] = result['Failure Count']
        test_result['error_count'] = result['Error Count']
        test_result['test_suite'] = result['Test Suite']['Name'].to_s
        test_result['pass_rate'] = result['Pass Rate']
        build_test_results.push(test_result)
        end
      ReportLog.info('Build test results hash constructed.')
    else
      raise construct_api_failure_msg(rtc_client)
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
    return build_test_results
  end

  # Convert number to percentage
  def get_percent (number)
    ('%3.1f' % (number.to_f * 100.0)).to_s + '%'
  end

  # Construct Slack message attachments
  def construct_slack_msg_attachments
    @build_pass_rate.nil? ? @build_pass_rate = get_build_pass_rate(@build_name, @test_category, @test_phase) : ()
    @build_test_results.nil? ? @build_test_results = get_build_test_results(@build_name, @test_category, @test_phase) : ()
    attachments = Array.new
    attachment = Hash.new
    attachment['fallback'] = "SLA-UI Cucumber Results for #{@build_name}." # plain-text summary for clients that do not show formatted text (IRC, notifications etc.)
    if @build_pass_rate['pass_rate'] < Constants::BUILD_PASS_DANGER_THRESHOLD
      attachment['color'] = Constants::SLACK_MSG_DANGER
    elsif @build_pass_rate['pass_rate'] < Constants::BUILD_PASS_WARNING_THRESHOLD
      attachment['color'] = Constants::SLACK_MSG_WARNING
    else attachment['color'] = Constants::SLACK_MSG_GOOD
    end
    attachment['pretext'] = 'You shall never pass.'
    attachment['author_name'] = '<mailto:ruifengm@sg.ibm.com|Ruifeng Ma>'
    attachment['author_icon'] = 'https://dl-web.dropbox.com/account_photo/get/dbid%3AAACA_VtmQtbmE8rLeLU5CsTaAlO855sgyTw?vers=1428332662027'
    attachment['title'] = "SLA-UI Cucumber Results (#{@build_name})"
    attachment['title_link'] = get_html_summary_url
    defect_count_str = ''
    @build_pass_rate['defect_count'].each do |key, value|
      defect_count_str +=  value.to_s + ' ' + key + ', '
    end
    attachment['text'] = "*Summary*\nPass rate: `#{get_percent(@build_pass_rate['pass_rate'])}`\nTest count: #{@build_pass_rate['test_count']}" +
        "\nFailure count: #{@build_pass_rate['failure_count']}\nError count: #{@build_pass_rate['error_count']}" +
        "\nDefect count: #{defect_count_str.chomp(', ')}\nSprint: #{@build_pass_rate['sprint']}\nGit branch: #{@build_pass_rate['git_branch']}" +
        "\nBuild version: #{@build_pass_rate['build_version']}\n\n"
    fields = Array.new
    test_suite_name_values = ''
    defect_values = ''
    defect_status_values = ''
    statistic_values = ''
    @build_test_results.each do |result|
      test_suite_name_values += "#{result['test_suite']}\n"
      if result['defect_url'].nil? || result['defect_number'].nil?
        # defect_values += "None\n"
        # defect_status_values += "N.A.\n"
      else
        # defect_values += "<#{result['defect_url']}|#{result['defect_number']}>\n"
        defect_values += "<#{result['defect_url']}|#{result['defect_number']}> #{result['defect_summary']}" +
            " | _#{result['defect_status'].nil? ? 'Status not available':result['defect_status']}_\n"
        defect_status_values += "#{result['defect_status'].nil? ? 'N.A.':result['defect_status']}\n"
      end
      statistic_values += "Total #{result['test_count'].to_s.rjust(3)}, #{get_percent(result['pass_rate'])} pass\n"
      ReportLog.info(result['test_count'].to_s.rjust(3))
    end
    fields.push(construct_field_hash('Test Suite', test_suite_name_values, true))
    fields.push(construct_field_hash('Statistics', statistic_values, true))
    fields.push(construct_field_hash('Defect', defect_values, false))
    # fields.push(construct_field_hash('Defect Status', defect_status_values, true))
    attachment['fields'] = fields
    attachment['footer'] = 'Presented by SLA team'
    attachment['ts'] = Time.now.to_i
    attachment['mrkdwn_in'] = ['text', 'fields']
    attachments.push(attachment)
    attachments
  end
end

# Construct field hash for Slack attachment
def construct_field_hash(title, value, is_short)
  {:title => title, :value => value, :short => is_short}
end
