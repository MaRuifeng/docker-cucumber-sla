# Log class
# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-Jul-12

require 'logger'

class ReportLog
  @@log_file_name = "cuke_report_ui_#{Time.now.utc.strftime('%Y%m%d%H%M%S').to_s}.log"
  @@log_root_path = "#{Dir.home}/cuke_report_logs"
  @@logger = Logger.new("#{@@log_root_path}/#{@@log_file_name}", 10, 1024000)

  @@logger.level = Logger::DEBUG
  @@logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime}]#{progname} #{severity} > #{msg}\n"
  end

  def self.get_logger
    return @@logger
  end

  def self.get_log_file_path
    return @@log_root_path + '/' + @@log_file_name
  end

  def self.info(msg)
    @@logger.info msg
  end

  def self.error(msg)
    @@logger.error msg
  end

  def self.debug(msg)
    @@logger.debug msg
  end

  def self.warn(msg)
    @@logger.warn msg
  end

  def self.fatal(msg)
    @@logger.fatal msg
  end

  def self.unknown(msg)
    @@logger.unknown msg
  end

  def self.entering(class_name, method_name)
    @@logger.debug ">> Entering #{class_name} : #{method_name}"
  end

  def self.exiting(class_name, method_name)
    @@logger.debug "<< Exiting #{class_name} : #{method_name}"
  end

  def self.close
    @@logger.close
  end

end