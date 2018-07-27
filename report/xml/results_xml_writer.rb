# This utility class contains a writer that re-constructs the TESTS-<feature name>.xml
# files generated by the automated Cucumber test
# to include RTC work item information for each test suite (feature) as node attributes based on results
# returned by the RTC publisher.
#
# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-Jul-18

require_relative 'results_xml_common'

class ResultsXMLWriter < ResultsXMLCommon

  @@class_name = self.name

  attr_reader :test_suite_defect_list, :test_suite_build_list, :output_xml_dir

  def initialize(xml_dir, log_dir, report_dir, output_xml_dir, test_suite_defect_list, test_suite_build_list)
    super(xml_dir, log_dir, report_dir)
    @test_suite_defect_list = test_suite_defect_list
    @test_suite_build_list = test_suite_build_list
    @output_xml_dir = output_xml_dir
  end

  # Read files from the JUnit XML directory and re-construct them into new ones
  def reconstruct_xml_results
    ReportLog.entering(@@class_name, __method__.to_s)
    Dir.mkdir @output_xml_dir unless Dir.exist? @output_xml_dir
    get_test_xml_files.each do |xml_path|
      xml_input_file = File.new(xml_path)
      ReportLog.info("Writing additional info (test suite owner and RTC defect etc.) into new test result XML file in directory #{@output_xml_dir}...")
      # using File.open block pattern to ensure the file is closed afterwards
      File.open(@output_xml_dir + '/' + File.basename(xml_path), 'w') do |xml_output_file|
        write_to_xml(xml_input_file, xml_output_file)
      end
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  private

  # Write additional information as attributes of 'testsuite' node into the new test result XML file
  def write_to_xml(xml_input_file, xml_output_file)
    ReportLog.entering(@@class_name, __method__.to_s)
    xml_doc = Document.new(xml_input_file)
    xml_doc.elements.each('testsuite') do |e|
      # Add RTC defect information as attributes
      suite_name = e.attribute('name').value
      suite_defect = @test_suite_defect_list.detect {|a| a['Test Suite'] == suite_name}
      suite_defect.keys.each do |key|
        if key != 'Test Suite'
          e.add_attribute(key, suite_defect[key])
        end
      end unless suite_defect.nil?
      # Add build information as attributes
      suite_build = @test_suite_build_list.detect {|a| a['Test Suite'] == suite_name}
      suite_build.keys.each do |key|
        if key != 'Test Suite'
          e.add_attribute(key, suite_build[key])
        end
      end unless suite_build.nil?
      # Add owners
      e.add_attribute('owner', get_test_suite_owner(xml_input_file.path))
      # Add test log link
      e.add_attribute('log', get_test_suite_log_link(suite_name))
      # Add cucumber report link
      e.add_attribute('cuke_report', get_test_cuke_report_link(suite_name))
    end
    xml_doc.write(:output => xml_output_file, :indent => 2)
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

end