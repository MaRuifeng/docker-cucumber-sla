# This module contains constant values used for cucumber reporting

module Constants

  # Test case (scenario) execution result statuses
  TEST_RESULT_STATUS           ||= {:success => 'SUCCESS', :failure => 'FAILURE', :error => 'ERROR'}

  # Test phases
  TEST_PHASE           ||= {:bvt => 'BVT', :ivt => 'IVT'}

  # Test category
  TEST_CTG_CUKE_GUI     ||= 'Cucumber_UI'
  TEST_CTG_RSPEC_API    ||= 'RSpec API'

  # RTC work item attribute value helpers
  DUE_WORKING_DAYS             ||= 5    # a week

  # RTC defect severity levels
  RTC_SEVERITY_BLOCKER            ||= 'Critical'
  RTC_SEVERITY_MAJOR              ||= 'Major'
  RTC_SEVERITY_NORMAL             ||= 'Moderate'
  RTC_SEVERITY_MINOR              ||= 'Minor'

  # RTC client REST interface types
  REST_TYPE_PUT                  ||= :put
  REST_TYPE_GET                  ||= :get
  REST_TYPE_POST                 ||= :post
  REST_TYPE_DELETE               ||= :delete

  # RTC client API parameters
  PARAM_TEST_CATEGORY                  ||= 'testCategory'
  PARAM_TEST_PHASE                     ||= 'testPhase'
  PARAM_DEFECT_SEVERITY                ||= 'defectSeverity'
  PARAM_DEFECT_NUM                     ||= 'defectNumber'
  PARAM_COMMENT                        ||= 'comment'
  PARAM_WORK_ITEM_NUM                  ||= 'workItemNumber'
  PARAM_TEST_SUITE_NAME                ||= 'testSuiteName'
  PARAM_BUILD_NAME                     ||= 'buildName'

  # RTC client API response JSON field keys
  JSON_KEY_RESULT                   ||= 'Result'
  JSON_KEY_IDENTIFIER               ||= 'Identifier'
  JSON_KEY_ERROR_MSG                ||= 'Error Message'

  # Slack message color
  SLACK_MSG_DANGER                   ||= 'danger'
  SLACK_MSG_WARNING                  ||= 'warning'
  SLACK_MSG_GOOD                     ||= 'good'

  # Build pass rate thresholds
  BUILD_PASS_DANGER_THRESHOLD                   ||= 0.9
  BUILD_PASS_WARNING_THRESHOLD                  ||= 0.95
  BUILD_PASS_GOOD_THRESHOLD                     ||= 1

end
