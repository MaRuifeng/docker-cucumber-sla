# This utility class contains a publisher that converges all JUnit XML reports produced by the
# cucumber scripts into a single XML file suitable for HTML report generation.
# An XSLT file is then applied to generate a summarized HTML report in JUnit format.
#
# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-July-19

require_relative 'results_xml_common'

class ResultsXMLPublisher < ResultsXMLCommon

  @@class_name = self.name

  attr_reader :result_dir

  def initialize(xml_dir, log_dir, result_dir)
    super(xml_dir, log_dir, nil)
    @result_dir = result_dir
  end

  def write_summary_report
    ReportLog.entering(@@class_name, __method__.to_s)
    # Write summary HTML file
    document = Nokogiri::XML(converge_xml_files.to_s)
    template = Nokogiri::XSLT(File.read('xml/junit-noframe.xsl'))
    ReportLog.info('Writing final summary HTML report...')
    transformed_document = template.transform(document)
    File.open("#{@result_dir}/summary.html", 'w').write(transformed_document)
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  private

  def converge_xml_files
    ReportLog.entering(@@class_name, __method__.to_s)
    xml_all_doc = Document.new
    # Add XML declaration
    xml_all_doc << XMLDecl.new
    # Add element tree
    testsuites = Element.new 'testsuites'
    testsuite_id = 0
    testsuites.add_attribute('logs', (@log_dir + '/').gsub("#{Dir.home}", ''))
    testsuites.add_attribute('timestamp', Time.now.getutc.strftime('%FT%T').to_s)
    get_test_xml_files.each do |xml_path|
      xml_input_file = File.new(xml_path)
      xml_doc = Document.new(xml_input_file)
      ReportLog.info("Converging all test result XML files found in directory #{@xml_dir}...")
      xml_doc.elements.each('testsuite') do |e|
        # Add useful attributes
        feature_name = e.attribute('name').value
        e.add_attribute('id', testsuite_id)
        e.add_attribute('package', feature_name)
        # e.add_attribute('package', get_test_package(xml_path)) # to be implemented when proper packaging of feature files is introduced
        # Add test properties
        properties = Element.new 'properties'
        property = Element.new 'property'
        property.add_attribute('name', 'test_env')
        property.add_attribute('value', 'docker')
        properties.add_element property
        e.add_element properties
        testsuites.add_element e
        testsuite_id = testsuite_id + 1
      end
    end
    xml_all_doc.add_element testsuites
    # Write summary XML file using File.open block to ensure it's closed afterwards
    File.open("#{@xml_dir}/summary.xml", 'w') do |file|
      xml_all_doc.write(:output => file, :indent => 2)
    end
    ReportLog.exiting(@@class_name, __method__.to_s)
    xml_all_doc
  end

end