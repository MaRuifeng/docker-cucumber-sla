# coding: utf-8
require 'watir-webdriver'

## DIRECTORIES
download_directory = "#{FigNewton.download_directory}"
results_directory = "#{FigNewton.results_directory}"
screenshot_directory = "#{FigNewton.screenshot_directory}"
log_directory = "#{FigNewton.log_directory}"

download_directory.gsub!('/', "\\") if Selenium::WebDriver::Platform.windows?
results_directory.gsub!('/', "\\") if Selenium::WebDriver::Platform.windows?
screenshot_directory.gsub!('/', "\\") if Selenium::WebDriver::Platform.windows?
log_directory.gsub!('/', "\\") if Selenium::WebDriver::Platform.windows?

Dir.mkdir download_directory unless Dir.exist? download_directory
Dir.mkdir results_directory unless Dir.exist? results_directory
Dir.mkdir log_directory unless Dir.exist? log_directory
Dir.mkdir screenshot_directory unless Dir.exist? screenshot_directory

## BROWSER
Watir.default_timeout = 30
::PageObject.default_element_wait = 20 # default is 5
client = Selenium::WebDriver::Remote::Http::Default.new
client.timeout = 180 # seconds – default is 60

firefox_profile = Selenium::WebDriver::Firefox::Profile.new
firefox_profile['browser.download.folderList'] = 2 # custom location
firefox_profile['browser.download.dir'] = download_directory
firefox_profile['browser.download.panel.shown'] = false
firefox_profile['browser.download.animateNotifications'] = false
firefox_profile['browser.helperApps.neverAsk.saveToDisk'] = 'attachment/csv, text/csv, text/plain, application/csv'
firefox_profile['browser.download.manager.showWhenStarting'] = false
firefox_profile['browser.download.manager.showAlertOnComplete'] = false
firefox_profile['browser.download.manager.closeWhenDone'] = true

## HOOKS
Before do |scenario|
  case FigNewton.browser.downcase.to_sym
    when :chrome
      browser = Watir::Browser.new :chrome, :http_client => client, :switches => %w[--test-type --ignore-certificate-errors --disable-popup-blocking --disable-translate]
    # --test-type switch is to exclude the 'Unsupported command-line flag:--ignore-certificate-errors' pop-up message
    when :firefox
      browser = Watir::Browser.new :firefox, :profile => firefox_profile
    else
      puts 'No valid browser type specified!'
  end
  browser.window.maximize
  @browser = browser

  # flags
  if !$ran_once_in_feature # flag to check whether ran once in a feature
    $ran_once_in_feature = false
  end
  if !$ran_once_in_outline # flag to check whether ran once in a scenario outline
    $ran_once_in_outline = false
  end 
  
  # scenario, scenario outline, feature
  case    # cannot use when Class directly as ScenarioOutlineExample inherits Scenario
    when scenario.instance_of?(Cucumber::RunningTestCase::Scenario)
      if $feature_name.nil? || $feature_name != scenario.feature.name
        # new feature encountered
        $log.nil? ? () : ($log.info("Feature completed: #{$feature_name}"); $log.info('=====FEATURE END====='); $log.close)
        $stdout_log.nil? ? () : ($stdout_log.info('=====FEATURE END====='); $stdout_log.close)
        $ran_once_in_feature = false
        $feature_name = scenario.feature.name
      end
      $scenario_info = scenario.name
      $scenario_outline_name = nil
    when scenario.instance_of?(Cucumber::RunningTestCase::ScenarioOutlineExample)
      if  $feature_name.nil? || $feature_name != scenario.scenario_outline.feature.name
        # new feature encountered
        $log.nil? ? () : ($log.info("Feature completed: #{$feature_name}"); $log.info('=====FEATURE END====='); $log.close)
        $stdout_log.nil? ? () : ($stdout_log.info('=====FEATURE END====='); $stdout_log.close)
        $ran_once_in_feature = false
        $feature_name = scenario.scenario_outline.feature.name
      end
      $scenario_info = scenario.scenario_outline.name

      if $scenario_outline_name.nil? || $scenario_outline_name != scenario.scenario_outline.name.gsub(/,.*Examples.*\(#\d+\)/, '')
        # new scenario outline encountered
        $ran_once_in_outline = false
        $scenario_outline_name = scenario.scenario_outline.name.gsub(/,.*Examples.*\(#\d+\)/, '')
      end
    # Cucumber version 1.3.18
    #  when Cucumber::Ast::Scenario
    #    $feature_name= scenario.scenario_outline.feature.title
    #    $scenario_info = scenario.name
    #  when Cucumber::Ast::OutlineTable::ExampleRow
    #    $feature_name= scenario.scenario_outline.feature.title
    #    $scenario_info = scenario.scenario_outline.name + " > " + scenario.name
    else
      $feature_name= 'Unknown-feature'
      $scenario_info = 'Unknown-scenario'
  end

  # log
  $log = Logger.new("#{log_directory}/#{$feature_name.gsub(/\s+/, '-')}-cuke_trace.log", 10, 1024000)
  $log.level = Logger::DEBUG
  $log.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime}][#{$feature_name}][#{$scenario_info}]#{progname} #{severity} > #{msg}\n"
  end
  
  $stdout_log = Logger.new("#{log_directory}/#{$feature_name.gsub(/\s+/, '-')}-stdout.log", 10, 1024000)
  $stdout_log.level = Logger::INFO
  $stdout_log.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime}]#{msg}\n"
  end
  
  def $stdout.write string
    # Monkey-patch STDOUT to make it output to the log file as well
    string.blank? ? () : $stdout_log.info(string)
    super
  end

  $log.info('=====FEATURE START=====') unless $ran_once_in_feature
  $log.info("Assigned testing portal URL: #{FigNewton.base_url}") unless $ran_once_in_feature
  $log.info("Feature to be run: #{$feature_name}") unless $ran_once_in_feature
  $ran_once_in_feature = true
  $log.info('######################SCENARIO Start######################')
  unless $scenario_outline_name.nil?
    $log.info("Scenario outline: #{$scenario_outline_name}")
  end
  $log.info("Scenario started: #{$scenario_info}")
  $stdout_log.info("Scenario started: #{$scenario_info}")
end

After do |scenario|
  # Capture screenshot on failure and include in report
  if scenario.failed?
    filename = "#{screenshot_directory}/error_#{scenario.feature.name.gsub(/\s+/, '').gsub(/\//, '')}_#{scenario.name.gsub(/\s+/, '').gsub(/\//, '')}_#{@current_page.class}_#{Time.new.strftime('%Y-%m-%d_%H%M%S')}.png"
    @current_page.save_screenshot(filename) if @current_page
    embed(filename, 'image/png')
    # [RF Ma] [2017-Apr-22]: currently authentication token is stored in window session storage which
    #                        disappears once window closes or session expires; such info should go to cookie store ultimately
    # browser.refresh # avoid the notorious 'target URL not well-formed' error of selenium
    # browser.goto(FigNewton.base_url) # back to start page
    $log.info("Scenario failed: #{$scenario_info}. Screenshot saved to #{filename}")
  else
    $log.info("Scenario passed: #{$scenario_info}")
  end
	# Ideally all scenarios should have a 'I log out' step at the end to go back to the splash page, this is just in case ...
	# if @browser.div(class: 'ssd-header').when_present.li(class: 'userInformation').present?
	# 	$log.info('User information panel is still present. Logging out now...')
	# 	log_out
	# elsif !@browser.div(class: 'splash-content').present?
	#   $log.info('Scenario did not end on the splash page. Forcing over...')
	#   browser.goto(FigNewton.base_url) # force to the splash page
	# end
  $log.info('######################SCENARIO END######################')
  $stdout_log.info("Scenario ended: #{$scenario_info}")
  # Clear cookies and session storage
  # $log.info(@browser.cookies.to_a)
  # @browser.cookies.to_a.each do |cookie|
  #   # $log.info(cookie)
  # end
  begin
    @browser.cookies.clear
    @browser.execute_script('window.sessionStorage.clear()') # execute JavaScript
    @browser.execute_script('window.localStorage.clear()') # execute JavaScript
  rescue => e
  ensure
    # Close the browser
    @browser.close if @browser
  end
end

at_exit do
  # last feature log
  $log.info("Feature completed: #{$feature_name}")
  $log.info('=====FEATURE END=====')
  $stdout_log.info('=====FEATURE END=====')
  # Close log
  $log.close
  $stdout_log.close
  # Remove the download directory
  download_directory = "#{FigNewton.download_directory}"
  FileUtils.rm_rf(download_directory)
end
