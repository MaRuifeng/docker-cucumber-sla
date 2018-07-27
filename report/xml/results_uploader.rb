# An FTP uploader to upload reports/results to report server
#
# Maintainer: ruifengm@sg.ibm.com
# Date: 2016-Jul-28

require 'net/ftp'
require_relative '../report_log'
require 'data_magic'
require 'find'

class ResultsUploader

  @@class_name = self.name

  include DataMagic
  # Load environment configuration data
  DataMagic.yml_directory = File.expand_path('../../', __FILE__)
  DataMagic.load('env_config.yml')

  attr_reader :result_dir

  def initialize(result_dir)
    @result_dir = result_dir
  end

  # Main uploader
  def upload
    ReportLog.entering(@@class_name, __method__.to_s)
    # FTP server credentials
    host = data_for(:report_server)[:host]
    user = data_for(:report_server)[:user]
    password = data_for(:report_server)[:password]
    port = data_for(:report_server)[:port]
    ReportLog.info("FTP server info: #{host} #{port} #{user}")
    # Log in and check available files at the default home directory (e.g htdocs/ on an IBM HTTP Server)
    ftp = Net::FTP.new
    ftp.connect(host, port)
    ftp.passive = true # both data and command channels are set up by the client
    ftp.login(user, password)
    # Create required directories recursively if not existing
    recursive_make_nested_dir(ftp, @result_dir, Dir.home)
    ReportLog.info("Completed making nested directories on the FTP server from \"#{@result_dir}\" with left boundary \"#{Dir.home}\".")
    # Upload recursively
    target_dir = @result_dir.gsub(Dir.home + '/', '')
    server_files = ftp.list((File.expand_path('..', @result_dir)).gsub(Dir.home, '').gsub(/^\//, '')) # an Array
    recursive_upload(ftp, @result_dir, target_dir, server_files)
    # Close FTP
    ftp.close
    ReportLog.info('Upload completed.')
    ReportLog.exiting(@@class_name, __method__.to_s)
  end

  private

  def recursive_make_nested_dir(ftp, source_dir, left_boundary)
    target_dir = source_dir.gsub(left_boundary, '').gsub(/^\//, '')
    if source_dir == left_boundary
      ReportLog.info("Left boundary #{left_boundary} reached.")
    else
      if ftp.list((File.expand_path('..', source_dir)).gsub(left_boundary, '').gsub(/^\//, '')).any? {|d| d.match(Regexp.new("\s#{File.basename(source_dir)}$"))}
        ReportLog.info("Directory exists on FTP server: #{target_dir}")
      else
        recursive_make_nested_dir(ftp, File.expand_path('..', source_dir), left_boundary)
        ReportLog.info("Creating #{target_dir} ...")
        ftp.mkdir(target_dir)
      end
    end
  end

  # Recursively upload directories and files
  # Note: unix-like hidden files (dotfiles) not included, use File::FNM_DOTMATCH flag or .* for Dir.glob to match them
  def recursive_upload(ftp, source_dir, target_dir, server_files)
    # check if the directory exists; create one on the server if not
    ReportLog.info("Checking target directory(make if not exist): #{target_dir}")
    ftp.mkdir(target_dir) unless server_files.any? {|d| d.match(Regexp.new("\s#{File.basename(target_dir)}$"))}
    # upload files
    ReportLog.info("Navigating into source directory: #{source_dir}")
    Dir["#{source_dir}/*"].each do |path|
      if File.stat(path).directory?
        ReportLog.info("Navigating into source sub-directory: #{path}")
        recursive_upload(ftp, path, target_dir + '/' + File.basename(path), ftp.list(target_dir))
      else
        # upload file in binary format
        ReportLog.info("Uploading file: #{path}")
        ftp.putbinaryfile(path, target_dir + '/' + File.basename(path))
      end
    end
  end

end