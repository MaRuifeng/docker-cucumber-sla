# A parent class for test result XML file handlers that holds commonly used functions
# - reader
# - writer
# - publisher
#
# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-Jul-18

require 'rexml/document'
require_relative '../constants'
require_relative '../report_log'
require 'data_magic'
require 'nokogiri'
require 'find'

class ResultsXMLCommon

  include REXML
  include DataMagic

  # Load environment configuration data
  DataMagic.yml_directory = File.expand_path('../../', __FILE__)
  DataMagic.load('env_config.yml')

  attr_accessor :xml_dir, :log_dir, :report_dir

  def initialize(xml_dir, log_dir, report_dir)
    @xml_dir = xml_dir
    @log_dir = log_dir
    @report_dir = report_dir
  end

  def get_test_xml_files
    @xml_dir.nil? ? (raise 'No XML file directory specified.') : Dir["#{@xml_dir}/TEST-*.xml"]
  end

  def get_test_suite_owner(xml_file_path)
    package_name = get_test_package(xml_file_path)
    data_for(:RTC_work_item_attr)["owner_#{package_name}".to_sym] || data_for(:RTC_work_item_attr)[:owner_default]
  end

  def get_test_package(xml_file_path)
    file_name = File.basename(xml_file_path)
    package_name = file_name[/features-[^\.]+/,0] || 'features'
    # package_name = package_name.chomp('-')
    package_name
  end

  def get_test_suite_log_link(test_suite_name)
    log_link = String.new
    if @log_dir.nil?
      raise 'No log directory specified.'
    else
      Dir["#{@log_dir}/*cuke_trace.log"].each do |file_path|
        # if file_path =~ Regexp.new(test_suite_name.gsub(/\s+/, "-"), Regexp::IGNORECASE)
        if file_path.split('/')[-1].gsub('-cuke_trace.log', '') == test_suite_name.gsub(/\s+/, '-')
          log_link = file_path.gsub("#{Dir.home}", '')
          break
        end
      end
      log_link
    end
  end

  def get_test_cuke_report_link(test_suite_name)
    report_link = String.new
    if @log_dir.nil?
      raise 'No cucumber report directory specified.'
    else
      Dir["#{@report_dir}/*.html"].each do |file_path|
        # if file_path =~ Regexp.new(feature_name.gsub(/\s+/, "-"), Regexp::IGNORECASE)
        if file_path.split('/')[-1].gsub('.html', '') == test_suite_name.gsub(/\s+/, '-')
          report_link = file_path.gsub("#{Dir.home}", '')
          break
        end
      end
      report_link
    end
  end

end
