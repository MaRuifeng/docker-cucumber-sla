# This results publisher manages the RTC defects created upon the JSON package produced
# by parsing the JUnit test results XML files.
# It works via the RTC Client REST APIs deployed on a web application server (e.g. WebSphere). 
# - Sync test results into the TEST DB
# - Create a defect for a test suite whose results contain failures/errors
# - Update defect content upon subsequent test suite executions, until the defect is closed
# - Close defect if test pass rate reaches standard

# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-July-05

require_relative 'rtc_client_rest_api'
require_relative 'rtc_rest_client'


class ResultsRTCPublisher
  include DataMagic

  @@class_name = self.name

  attr_accessor :api, :params, :payload

  def initialize
    @api = nil
    @params = nil
    @payload = nil
  end

  ##
  # Sync test suites from the results obtained to TEST DB
  ##
  def sync_test_suites(test_category, test_suite_result_list)
    ReportLog.entering(@@class_name, __method__.to_s)
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_syncTestSuites])
    @payload = JSON.generate(test_suite_result_list)
    @params = Hash.new
    @params[Constants::PARAM_TEST_CATEGORY] = test_category
    ReportLog.info("Set up the RTC REST client and start syncing test suites for test category #{test_category}...")
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
    rtc_client.run_api
    rtc_client.run_successfully ? ReportLog.info('Sync completed.') : (raise construct_api_failure_msg(rtc_client))
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  ##
  # Sync test cases from the results obtained to TEST DB
  ##
  def sync_test_cases(test_suite_result_list)
    ReportLog.entering(@@class_name, __method__.to_s)
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_syncTestCases])
    @payload = JSON.generate(test_suite_result_list)
    @params = nil
    ReportLog.info('Set up the RTC REST client and start syncing test cases...')
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
    rtc_client.run_api
    rtc_client.run_successfully ? ReportLog.info('Sync completed.') : (raise construct_api_failure_msg(rtc_client))
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  ##
  # Sync application builds from the results obtained to TEST DB
  ##
  def sync_app_builds(test_suite_result_list)
    ReportLog.entering(@@class_name, __method__.to_s)
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_syncAppBuilds])
    @payload = JSON.generate(test_suite_result_list)
    @params = nil
    ReportLog.info('Set up the RTC REST client and start syncing application builds...')
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
    rtc_client.run_api
    rtc_client.run_successfully ? ReportLog.info('Sync completed.') : (raise construct_api_failure_msg(rtc_client))
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  ##
  # Add test results to TEST DB
  ##
  def add_test_results(test_phase, test_suite_result_list)
    ReportLog.entering(@@class_name, __method__.to_s)
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_addTestResults])
    @payload = JSON.generate(test_suite_result_list)
    @params = Hash.new
    @params[Constants::PARAM_TEST_PHASE] = test_phase
    ReportLog.info('Set up the RTC REST client and start adding test results...')
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_POST, @api, @params, @payload)
    rtc_client.run_api
    rtc_client.run_successfully ? ReportLog.info('Add completed.') : (raise construct_api_failure_msg(rtc_client))
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  ##
  # Sync build pass rate
  ##
  def sync_build_pass_rate(test_suite_result_list)
    ReportLog.entering(@@class_name, __method__.to_s)
    build_list = Array.new
    test_suite_result_list.each { |t| build_list.push(t['Build']['BuildName']) }
    build_list.uniq!
    build_list.each do |b|
      @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_syncBuildPassRate])
      @payload = nil
      @params = Hash.new
      @params[Constants::PARAM_BUILD_NAME] = b
      ReportLog.info("Set up the RTC REST client and start syncing pass rate for build #{b}...")
      rtc_client = RTCRestClient.new(Constants::REST_TYPE_GET, @api, @params, @payload)
      rtc_client.run_api
      rtc_client.run_successfully ? ReportLog.info('Sync completed.') : (raise construct_api_failure_msg(rtc_client))
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  ##
  # Publish test results to RTC
  # by creating/updating defects for test suites with failures/errors,
  # and then store the defects to the TEST DB.
  ##
  def publish_test_results(test_category, test_phase, test_suite_result_list)
    ReportLog.entering(@@class_name, __method__.to_s)

    test_suite_result_list.each do |test_suite_result|
      test_suite_name = test_suite_result['TestSuiteName']
      test_count = test_suite_result['TestCount'].to_i
      error_count = test_suite_result['ErrorCount'].to_i
      failure_count = test_suite_result['FailureCount'].to_i

      pass_rate = 1 - (error_count.to_f + failure_count.to_f)/test_count.to_f

      input = Hash.new
      input[:RTCConfig] = data_for(:RTC_config)

      if pass_rate < get_threshold_value(data_for(:RTC_defect_threshold)[:minor_threshold])
        # pass rate standard not met, create or update existing defect
        if pass_rate < get_threshold_value(data_for(:RTC_defect_threshold)[:blocker_threshold])
          defect_severity = Constants::RTC_SEVERITY_BLOCKER
        elsif pass_rate < get_threshold_value(data_for(:RTC_defect_threshold)[:major_threshold])
          defect_severity = Constants::RTC_SEVERITY_MAJOR
        elsif pass_rate < get_threshold_value(data_for(:RTC_defect_threshold)[:normal_threshold])
          defect_severity = Constants::RTC_SEVERITY_NORMAL
        else
          defect_severity = Constants::RTC_SEVERITY_MINOR
        end

        # Check from the TEST DB whether there is already an open defect for this test suite
        # if yes, update it
        # if no, create a new one

        # set up RTC client and run /getOpenTestAutoDefect API
        ReportLog.info('Pass rate beneath standard. Update existing open defect or create a new one.')
        ReportLog.info("Looking for open defect for test suite #{test_suite_name} ...")
        @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_getOpenTestAutoDefect])
        @payload = JSON.generate(input)
        @params = Hash.new
        @params[Constants::PARAM_TEST_SUITE_NAME] = test_suite_name
        rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
        rtc_client.run_api
        if rtc_client.run_successfully
          @params = Hash.new
          @params[Constants::PARAM_TEST_CATEGORY] = test_category
          @params[Constants::PARAM_TEST_PHASE] = test_phase
          @params[Constants::PARAM_DEFECT_SEVERITY] = defect_severity
          input['TestSuiteResult'] = test_suite_result
          @payload = JSON.generate(input)
          if rtc_client.response_body.fetch(Constants::JSON_KEY_RESULT).nil?
            # no existing open defect, create a new one
            ReportLog.info('Open defect not found. Creating a new one...')
            # set up RTC client and run /createTestAutoDefect API
            @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_createTestAutoDefect])
            rtc_client = RTCRestClient.new(Constants::REST_TYPE_POST, @api, @params, @payload)
            rtc_client.run_api
            if rtc_client.run_successfully
              ReportLog.info('Created a new defect.')
              ReportLog.info("RTC client response: #{rtc_client.response_body.to_s}")
            else
              raise construct_api_failure_msg(rtc_client)
            end
          else
            # existing open defect found, update it
            ReportLog.info('Open defect found. Updating its content...')
            # set up RTC client and run /updateTestAutoDefect API
            @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_updateTestAutoDefect])
            @params[Constants::PARAM_DEFECT_NUM] = rtc_client.response_body.fetch(Constants::JSON_KEY_RESULT).fetch('Defect Number').to_s
            rtc_client = RTCRestClient.new(Constants::REST_TYPE_POST, @api, @params, @payload)
            rtc_client.run_api
            if rtc_client.run_successfully
              ReportLog.info('Updated the open defect.')
              ReportLog.info("RTC client response: #{rtc_client.response_body.to_s}")
            else
              raise construct_api_failure_msg(rtc_client)
            end
          end
        else
          raise construct_api_failure_msg(rtc_client)
        end
      else
        # pass rate reached standard, close open defect automatically
        # Check from the TEST DB whether there is already an open defect for this test suite
        # if yes, close it
        # if no, do nothing, you are good

        # set up RTC client for /getOpenTestAutoDefect API
        ReportLog.info('Pass rate reached standard. Close open defect if there is any.')
        ReportLog.info("Looking for open defect for test suite #{test_suite_name} ...")
        @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_getOpenTestAutoDefect])
        @payload = JSON.generate(input)
        @params = Hash.new
        @params[Constants::PARAM_TEST_SUITE_NAME] = test_suite_name
        rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
        rtc_client.run_api
        if rtc_client.run_successfully
          @params = Hash.new
          if rtc_client.response_body.fetch(Constants::JSON_KEY_RESULT).nil?
            # do nothing
          else
            # existing open defect found, close it
            ReportLog.info('Open defect found. Closing it...')
            # set up RTC client and run /closeTestAutoDefect API
            @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_closeTestAutoDefect])
            @params[Constants::PARAM_DEFECT_NUM] = rtc_client.response_body.fetch(Constants::JSON_KEY_RESULT).fetch('Defect Number').to_s
            @params[Constants::PARAM_COMMENT] = "Closed defect upon test execution at #{test_suite_result['ExecutionTimestamp']} "
                                              + "from build #{test_suite_result['Build']['BuildName']} "
                                              + "with an acceptable pass rate of #{pass_rate}."
            @params[Constants::PARAM_BUILD_NAME] = test_suite_result['Build']['BuildName']
            rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
            rtc_client.run_api
            if rtc_client.run_successfully
              ReportLog.info('Closed the open defect.')
              ReportLog.info("RTC client response: #{rtc_client.response_body.to_s}")
            else
              raise construct_api_failure_msg(rtc_client)
            end
          end
        else
          raise construct_api_failure_msg(rtc_client)
        end
      end
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  ##
  # Get RTC defect info to be published to respective test suite execution result XML file for reporting
  ##
  def get_latest_defect_for_xml_publish
    ReportLog.entering(@@class_name, __method__.to_s)
    test_suite_defect_list = Array.new
    # set up RTC client
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_getAllLatestRTCDefects])
    @params = nil
    @payload = nil
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_GET, @api, @params, @payload)
    # run API
    ReportLog.info('Retrieving latest defects for all test suites...')
    rtc_client.run_api
    if rtc_client.run_successfully
      ReportLog.info('All latest defects retrieved. Constructing test suite defect list...')
      result_hash = rtc_client.response_body.fetch(Constants::JSON_KEY_RESULT)
      result_hash.each do |result|
        test_suite_defect = Hash.new
        test_suite_defect['defect_number'] = result['Defect Number'].to_s
        test_suite_defect['defect_status'] = result['Defect Status'].to_s
        test_suite_defect['defect_url'] = result['Defect Link'].to_s
        test_suite_defect['defect_filing_date'] = result['Defect Filed Timestamp'].to_s[0..9]
        test_suite_defect['Test Suite'] = result['Test Suite'].to_s
        test_suite_defect_list.push(test_suite_defect)
      end
      ReportLog.info('Test suite defect list constructed.')
    else
      raise construct_api_failure_msg(rtc_client)
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
    return test_suite_defect_list
  end

  ##
  # Get test suite builds to be published to respective test suite execution result XML file for reporting
  ##
  def get_latest_build_for_xml_publish
    ReportLog.entering(@@class_name, __method__.to_s)
    test_suite_build_list = Array.new
    # set up RTC client
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_getLatestBuildTestResults])
    @params = nil
    @payload = nil
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_GET, @api, @params, @payload)
    # run API
    ReportLog.info('Retrieving latest test results (builds) for all test suites...')
    rtc_client.run_api
    if rtc_client.run_successfully
      ReportLog.info('All latest test results (builds) retrieved. Constructing test suite build list...')
      result_hash = rtc_client.response_body.fetch(Constants::JSON_KEY_RESULT).fetch('Latest Test Suite Results')
      result_hash.each do |result|
        test_suite_build = Hash.new
        test_suite_build['build'] = result['Build']['Build Name'].to_s
        test_suite_build['git_branch'] = result['Build']['Git Branch'].to_s
        test_suite_build['sprint'] = result['Build']['Sprint'].to_s
        test_suite_build['Test Suite'] = result['Test Suite']['Name'].to_s

        test_suite_build_list.push(test_suite_build)
      end
      ReportLog.info('Test suite build list constructed.')
    else
      raise construct_api_failure_msg(rtc_client)
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
    return test_suite_build_list
  end

  ##
  # Sync status of all RTC defects
  ##
  def sync_rtc_defect_status
    ReportLog.entering(@@class_name, __method__.to_s)
    # set up RTC client
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_syncRTCDefectStatus])
    input = Hash.new
    input[:RTCConfig] = data_for(:RTC_config)
    @payload = JSON.generate(input)
    @params = nil
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
    # run API
    ReportLog.info('Syncing all RTC defect status...')
    rtc_client.run_api
    rtc_client.run_successfully ? ReportLog.info('Sync completed.') : (raise construct_api_failure_msg(rtc_client))
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  ##
  # Get work item status
  ##
  def get_work_item_status(item_number)
    ReportLog.entering(@@class_name, __method__.to_s)
    # set up RTC client
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_getWorkItemStatus])
    input = Hash.new
    input[:RTCConfig] = data_for(:RTC_config)
    @payload = JSON.generate(input)
    @params = Hash.new
    @params[Constants::PARAM_WORK_ITEM_NUM] = item_number
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
    # run API
    ReportLog.info('Getting work item status...')
    rtc_client.run_api
    if rtc_client.run_successfully
      ReportLog.info('Work item status retrieved')
      ReportLog.info("RTC client response: #{rtc_client.response_body.to_s}")
    else
      raise construct_api_failure_msg(rtc_client)
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  ##
  # Exit established RTC instance
  ##
  def exit_RTC
    ReportLog.entering(@@class_name, __method__.to_s)
    # set up RTC client
    @api = RTCClientRestAPI.new(data_for(:RTC_client_api_url)[:RTC_REST_URL_exitRTC])
    input = Hash.new
    input[:RTCConfig] = data_for(:RTC_config)
    @payload = JSON.generate(input)
    @params = nil
    rtc_client = RTCRestClient.new(Constants::REST_TYPE_PUT, @api, @params, @payload)
    # run API
    ReportLog.info('Exiting the established RTC instance...')
    rtc_client.run_api
    rtc_client.run_successfully ? ReportLog.info('Exit completed.') : (raise construct_api_failure_msg(rtc_client))
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  def construct_api_failure_msg(rtc_client)
    return "RTC client API failure: #{rtc_client.api.url} >> #{rtc_client.response_body[Constants::JSON_KEY_ERROR_MSG]}"
  end

  def get_threshold_value(threshold_str)
    return threshold_str.gsub('%', '').to_f/100
  end

  private :construct_api_failure_msg, :get_threshold_value
end
