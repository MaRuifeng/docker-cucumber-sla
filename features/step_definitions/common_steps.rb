# Common step definitions used across various features
# Note that step definitions should be abstract enough to avoid duplicates

# Initiated By: ruifengm@sg.ibm.com
# Date: 2017-Apr-20

# ============== UI Steps ============== #
# 1. Open Splash Page
#	2. Login as 
# 3. Set emergency to YES
#	4. Select Change Type
#	5. Log out
#	6. Open SSD Work Tab
#	7. Click on Server Tab and open Server Page
#	8. Search for a server by its name
#	9. Initiate a request for server 
#	10. Submit Bundle
#	11. Verify Successful Execution

Given(/^I opened up the welcome splash page of SLA UI$/) do
  begin
    # on_page(SplashPage)
    # on_page(LoginPage)
    visit(LoginPage)
    on_page(IBMIdLoginPage)
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully landed on the welcome splash page.')
end

When(/^I am logged into the SLA UI as a(n)? "([^"]*)"$/) do |article, user_role|
  $log.info("Current user role: #{user_role}")
  begin
    # continue_navigation_to(LoginPage, :using => :default).login_as(user_role)
    # on_page(LoginPage).login_as(user_role)
    on_page(IBMIdLoginPage).login_as(user_role)
    wait_for_spinner
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("Successfully logged in as #{user_role}.")
end

When(/^I select the emergency request option$/) do
	begin
		set_emergency #calling UIHelper's set_emergency method
	rescue Exception => error
		$log.error("#{error.class}: #{error.message}")
		raise
  end
end

When(/^I select a Change Category and Change Type for "([^"]*)"$/) do |change_type|
  begin
    on(ChangeTypeSelectionPage) do |page|
      page.select_ssd_oracle_reporting_option change_type #added change_types for "oracle_standby_sync" in default.yml
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

When(/^I log out$/) do
  begin
    log_out
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully logged out.')
end

When(/^I opened up the work pane for Self Service Delivery$/) do
  begin
    on_page(MainPage).open_ssd_work_pane
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully opened the work pane for SSD.')
end

When(/^I opened up the work pane for SSD Admin$/) do
  begin
    on_page(MainPage) do |page|
      page.open_admin_work_pane
      page.open_ssd_admin_work_pane
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully opened the work pane for SSD Admin.')
end

When(/^I open up the SSD server page$/) do
  begin
    on_page(MainPage) do |page|
      page.server_page_element.when_present(5)
      page.server_page
    end
    wait_for_spinner
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully opened the server page.')
end

When(/^I search for server ([^"]*) by its name$/) do |server_id|
  begin
    @expected_server_info = FigNewton.send("#{server_id}_server").to_hash
    on_page(ServerListPage).search_server(@expected_server_info[:server_name])
    wait_for_spinner
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("Search completed for server #{@expected_server_info[:server_name]}.")
end

When(/^I click on the action button to initiate a request for server ([^"]+)$/) do |server_id|
  begin
    on_page(ServerListPage).init_server_request(@expected_server_info[:server_name])
    wait_for_spinner
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully initiated a request.')
end

And(/^I add this change request to bundle on DRF UI$/) do
  $log.info("Adding Change Request to Bundle..")
  begin
    on(ChangeRequestPage).add_change_request_to_bundle_common
    $log.info("Finished Adding Change Request to Bundle!")
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

Then(/^I should see that the status of the change request is "([^"]+)"$/) do |status|
  $log.info("Pending for the change request with ID #{@request_id} to be executed...")
  begin
		on_page(RequestListPage).get_current_execution_status(@request_id).should eq(status)
	rescue Exception => error
		$log.error("#{error.class}: #{error.message}")
		raise
  end
  $log.info("Current status of change request #{@request_id} is #{status}.")
end

Then(/^I should see that the execution status of the change request is "([^"]+)"$/) do |status|
  $log.info("Pending for the change request with ID #{@request_id} to be completed...")
  begin
		on_page(RequestListPage).get_final_execution_status(@request_id).should eq(status)
	rescue Exception => error
		$log.error("#{error.class}: #{error.message}")
		raise
  end
  $log.info("Verified execution status of change request #{@request_id} to be #{status}.")
end

Then(/^I open up the bundle details page$/) do
  $log.info("Openning up the bundle details page for change request #{@request_id} ...")
  begin
    on_page(RequestListPage).open_request_bundle_details @request_id
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("The bundle details page for change request #{@request_id} is opened.")
end

Then(/^I pick up the BPM process ID from the bundle details page$/) do
  $log.info('Getting BPM process ID from the bundle details page...')
  begin
    @bpm_process_id = on_page(BundleDetailsPage).get_bpm_process_id
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("Spawned BPM process ID is #{@bpm_process_id}.")
end

When(/^I open up the SSD change request page$/) do
  begin
    on_page(MainPage) do |page|
      page.request_page_element.when_present(5)
      page.request_page
    end
    wait_for_spinner
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully opened the request page.')
end

Given(/^I log into the SLA BPM Process Portal as a(n)? "([^"]*)"$/) do |article, user_role|
  $log.info("Logging into BPM. Current user role: #{user_role.split(" ").last.downcase}")
  begin
    visit(BPMLoginPage)
    on_page(IBMIdLoginPage).login_as(user_role)
    # on(BPMProcessPortalPage).launch_work_tasks
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

Then(/^I should get an "([^"]*)" on DRF UI for "([^"]*)"$/) do |error_message, feature|
  $log.info("Validating #{feature} scenario")
  begin
		validate_error_popup error_message
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

And(/^I log out from SLA BPM$/) do
  $log.info("Logging out the Current user from BPM Process Portal")
  begin
		on(BPMLoginPage).logout
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

And(/^I "([^"]*)" the "([^"]*)" change request via the BPM process ID$/) do |action, resource_name|
  $log.info("Processing change request of category #{resource_name} with action #{action} in BPM ... ")
  begin
    on(BPMProcessPortalPage).open_task_by_id @bpm_process_id
    on(BPMApprovalPage).process_change_request action, resource_name
    on(BPMApprovalPage).submit_decision
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

# ============== UI Steps ============== #

# ============== Support Steps ============== #

And (/^I clear the browser cookies from the filesystem and restart it/) do
  begin
    @browser.close
    case FigNewton.browser.downcase.to_sym
      when :chrome
        # clear cookies
        `find /tmp/.org.chromium.Chromium.*/Default -name Cookies -delete`
        # restart
        client = Selenium::WebDriver::Remote::Http::Default.new
        client.timeout = 180 # seconds – default is 60
        @browser = Watir::Browser.new :chrome, :http_client => Selenium::WebDriver::Remote::Http::Default.new, :switches => %w[--test-type --ignore-certificate-errors --disable-popup-blocking --disable-translate]
      when :firefox
        # clear cookies
        `find /tmp/webdriver-profile* -name 'cookies.sqlite' -delete`
        # restart
        @browser = Watir::Browser.new :firefox
      else
        puts 'No valid browser type specified!'
    end
    @browser.window.maximize
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully removed browser cookies from the file system and restarted the browser.')
end

Given(/^I have run the recipes? from below cookbooks? to set (pre|post)-conditions on the "([^"]*)" server$/) do |condition, platform, table|
  begin
    unless $ran_once_in_outline
			server_data = FigNewton.send("#{platform}_server").to_hash
			server_name = server_data[:server_name]
			server_ip = server_data[:ip]
			username = server_data[:username]
			password = server_data[:password]
			$log.info("Invoking the Chef helper to set pre-conditions for server #{server_name} #{server_ip}")
			recipe_list = ''
			table.hashes.each do |entry|
				recipe_list += 'recipe[' + entry[:COOKBOOK] + '::' + entry[:RECIPE] + '],'
			end
			recipe_list = recipe_list.gsub(/,$/, '')
			$log.info("Running recipes: #{recipe_list} ")
      if platform =~ /.*windows.*/i
        $log.info("Windows platform detected: #{platform}")
        cmd = "whoami && cd chef_helper && knife winrm #{server_ip} \"chef-client -o '#{recipe_list}'\" --manual-list --winrm-user #{username} --winrm-password #{password}"
      else
        $log.info("Redhat platform detected: #{platform}")
				cmd = "whoami && cd chef_helper && knife ssh #{server_ip} \"chef-client -o '#{recipe_list}' -c /opt/IBM/cobalt/etc/chef/client.rb\" -x #{username} -P #{password}"
      end
			output = `#{cmd} 2>&1` # redirect stderr to stdout
			$log.info("Chef knife command output:\n#{output}")
			if $?.exitstatus != 0
				$log.info("Chef knife command exited with status code #{$?.exitstatus}.")
				raise "Chef knife command exited with status code #{$?.exitstatus}. Check the cucumber log for details."
			end
			$log.info("Invoking the step to run custom chef-client...")
			step %{I have run the custom chef-client to refresh node information on the "#{platform}" server}
      $ran_once_in_outline = true # useless if the invoked step is run successfully, but no harm to keep
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

And(/^I have run the custom chef-client to refresh node information on the "([^"]*)" server$/) do |platform|
  begin
    unless $ran_once_in_outline
			server_data = FigNewton.send("#{platform}_server").to_hash
			server_name = server_data[:server_name]
			server_ip = server_data[:ip]
			username = server_data[:username]
			password = server_data[:password]
			$log.info("Running cobalt custom chef-client to refresh node information for server #{server_name} #{server_ip}")
      if platform =~ /.*windows.*/i
        $log.info("Windows platform detected: #{platform}")
				cmd = "whoami && cd chef_helper && knife winrm #{server_ip} \"C:\\IBM\\cobalt\\embedded\\bin\\ruby.exe C:\\IBM\\cobalt\\bin\\chef-client --node-name #{server_name} -c C:\\IBM\\cobalt\\chef\\client.rb\" --manual-list --winrm-user #{username} --winrm-password #{password}"
      else
        $log.info("Redhat platform detected: #{platform}")
        cmd = "whoami && cd chef_helper && knife ssh #{server_ip} \"/opt/IBM/cobalt/etc/chef/run_chef_client.sh --node-name #{server_name} -c /opt/IBM/cobalt/etc/chef/client.rb\" -x #{username} -P #{password}"
      end
			output = `#{cmd} 2>&1` # redirect stderr to stdout
			$log.info("Chef knife command output:\n#{output}")
			if $?.exitstatus != 0
				$log.info("Chef knife command exited with status code #{$?.exitstatus}.")
				raise "Chef knife command exited with status code #{$?.exitstatus}. Check the cucumber log for details."
			end
      $ran_once_in_outline = true
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end
# ============== Support Steps ============== #
