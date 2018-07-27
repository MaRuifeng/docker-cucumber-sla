When(/^I open up the Automation Provider Proxy Instances page$/) do
  begin
    on_page(MainPage) do |page|
      page.app_config_page_element.when_present(5)
      page.app_config_page
    end
    wait_for_spinner
    sleep 3
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully opened the automation provider proxy configuration page.')
end

Then(/^I should see a provider of type ([^"]+) and fqdn ([^"]+) listed in the table$/) do |provider_type, provider_fqdn|
  begin
    @expected_app_details = data_for("admin_app_instance/#{provider_type}")[provider_fqdn.to_s]
    app_info_in_table = on_page(AppListPage).get_app_info_in_table(provider_fqdn)
    app_info_in_table[:app_type].should eq(@expected_app_details['Automation Provider'.to_sym])
    case provider_type
      when 'hmc'
        app_info_in_table[:app_name].should eq(@expected_app_details[:fqdn])
      when 'vmware'
        app_info_in_table[:app_name].should eq(@expected_app_details[:server])
      when 'ipcenter'
        # TODO
      else
        $log.info("The provider type '#{provider_type}' given is not valid.")
        raise "Invalid provider type '#{provider_type}' requested!"
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Automation provider proxy in table verified.')
end

And(/^I click the show button to get the details of the provider of fqdn ([^"]+)$/) do |provider_fqdn|
  begin
    on_page(AppListPage).show_app_details(provider_fqdn)
    wait_for_spinner
    sleep 3
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Automation provider proxy details page opened.')
end

Then(/^I should see the provider attributes match the actual values$/) do
  begin
    actual_app_details = on_page(AppDetailsPage).get_app_details
    actual_app_details.delete(:id)
    actual_app_details.delete(:access_key_id)
    timestamp_regex = Regexp.new(data_for('admin_app_instance/regex_string')[:time_regex].to_s)
    actual_app_details[:created_at].should match(timestamp_regex)
    actual_app_details[:updated_at].should match(timestamp_regex)
    actual_app_details.delete(:created_at)
    actual_app_details.delete(:updated_at)
    actual_app_details.should eq(@expected_app_details)
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Automation provider proxy details verified.')
end

And(/^I add a new provider of type ([^"]+) and fqdn ([^"]+)$/) do |provider_type, provider_fqdn|
  begin
    new_app_details = data_for("admin_app_instance/#{provider_type}")[provider_fqdn.to_s]
    on_page(AppListPage).add_new_app
    wait_for_spinner
    on_page(AppAddNewPage) do |page|
      page.select_provider_type(provider_type)
      case provider_type
        when 'hmc'
          page.add_hmc(new_app_details)
        when 'vmware'
          page.add_vmware(new_app_details)
        when 'ipcenter'
          # TODO
        else
          $log.info("The provider type '#{provider_type}' given is not valid.")
          raise "Invalid provider type '#{provider_type}' requested!"
      end
      wait_for_spinner
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("New automation provider proxy of type #{provider_type} requested to be added.")
end

And(/^I delete an existing provider of type ([^"]+) and fqdn ([^"]+)$/) do |provider_type, provider_fqdn|
  begin
    on_page(AppListPage).delete_app(provider_fqdn)
    wait_for_spinner
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("Existing automation provider proxy of fqdn #{provider_fqdn} requested to be deleted.")
end

Then(/^I should see that a new provider of type ([^"]+) and fqdn ([^"]+) is successfully added$/) do |provider_type, provider_fqdn|
  begin
    step %{I should see a provider of type #{provider_type} and fqdn #{provider_fqdn} listed in the table}
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("New automation provider proxy #{provider_fqdn} successfully added.")
end

Then(/^I should see that the existing provider of type ([^"]+) and fqdn ([^"]+) is successfully deleted$/) do |provider_type, provider_fqdn|
  begin
    on_page(AppListPage).get_all_app_names_in_table.should_not include(provider_fqdn)
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("Existing automation provider proxy #{provider_fqdn} successfully deleted.")
end