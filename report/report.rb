# Cucumber test result report runner

# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-July-19


require '../report/xml/results_xml_reader'
require '../report/xml/results_xml_writer'
require '../report/xml/results_xml_publisher'
require '../report/xml/results_uploader'
require '../report/rtc/results_RTC_publisher'
require '../report/rtc/results_notifier'

#########
# Actual report execution (main function)
#########

begin
  include DataMagic

  ReportLog.info('===============Cucumber results publish log started===============')

  test_phase = Constants::TEST_PHASE[ENV['TEST_PHASE'].to_sym]
  build_name = ENV['APP_BUILD']

  if !ENV['CUCUMBER_ERROR'].nil? && ENV['CUCUMBER_ERROR'] == 'true'
    # Email notification
    notifier = ResultsNotifier.new(Constants::TEST_CTG_CUKE_GUI, test_phase, build_name)
    notifier.send_cucumber_error_email(ENV['CUCUMBER_STDERR'].to_s)
  else
    # Get test results from XML files into an Array
    xml_file_dir = data_for(:dir_config)[:junit_directory]
    log_file_dir = data_for(:dir_config)[:log_directory]
    xml_reader = ResultsXMLReader.new(xml_file_dir, log_file_dir, build_name)
    xml_reader.construct_test_suite_result_list

    # Run RTC publisher
    results_rtc_publisher = ResultsRTCPublisher.new
    results_rtc_publisher.sync_test_suites(Constants::TEST_CTG_CUKE_GUI, xml_reader.test_suite_result_list)
    results_rtc_publisher.sync_test_cases(xml_reader.test_suite_result_list)
    results_rtc_publisher.sync_app_builds(xml_reader.test_suite_result_list)
    results_rtc_publisher.add_test_results(test_phase, xml_reader.test_suite_result_list)
    results_rtc_publisher.sync_build_pass_rate(xml_reader.test_suite_result_list)
    results_rtc_publisher.sync_rtc_defect_status
    results_rtc_publisher.publish_test_results(Constants::TEST_CTG_CUKE_GUI, test_phase, xml_reader.test_suite_result_list)
    test_suite_defect_list = results_rtc_publisher.get_latest_defect_for_xml_publish
    test_suite_build_list = results_rtc_publisher.get_latest_build_for_xml_publish

    # Update additional information (RTC, test log, cucumber report and owner etc.) back into XML files
    report_file_dir = data_for(:dir_config)[:report_directory]
    output_xml_file_dir = data_for(:dir_config)[:output_xml_directory]
    results_writer = ResultsXMLWriter.new(xml_file_dir, log_file_dir, report_file_dir, output_xml_file_dir, test_suite_defect_list, test_suite_build_list)
    results_writer.reconstruct_xml_results

    # Write final summary HTML
    result_file_dir = data_for(:dir_config)[:result_directory]
    results_xml_publisher = ResultsXMLPublisher.new(output_xml_file_dir, log_file_dir, result_file_dir)
    results_xml_publisher.write_summary_report

    # Upload to report server
    results_uploader = ResultsUploader.new(data_for(:dir_config)[:result_directory])
    results_uploader.upload

    # Email & Slack notification
    notifier = ResultsNotifier.new(Constants::TEST_CTG_CUKE_GUI, test_phase, build_name)
    notifier.send_email
    notifier.post_to_slack

    # Exit established RTC instance
    # Note: it's mandatory to tear down the instance on the server hosting the RTC Web Client APIs
    #       so as to ensure the project repository gets refreshed upon next log in
    results_rtc_publisher.exit_RTC
  end

  ReportLog.info('===============Cucumber results publish log ended===============')
  ReportLog.close
rescue Exception => error
  ReportLog.error("#{error.class}: #{error.message}")
  raise
end
