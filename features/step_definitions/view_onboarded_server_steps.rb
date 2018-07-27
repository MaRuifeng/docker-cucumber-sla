## Positive

Then(/^I should see server ([^"]+) listed in the table$/) do |server_id|
  begin
    @expected_server_info.delete_if {|key, value| key == :username}
    @expected_server_info.delete_if {|key, value| key == :password}
    $log.info("Expected server info in table row: #{@expected_server_info}")
    server_info = on_page(ServerListPage).get_server_info_in_row(@expected_server_info[:server_name])
    $log.info("Displayed server info in table row: #{server_info}")
    server_info.should eq(@expected_server_info)
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Server information verified.')
end

When(/^I expand the details of server ([^"]+)$/) do |server_id|
  begin
    on_page(ServerListPage).expand_server_details(@expected_server_info[:server_name])
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully expanded server details.')
end

Then(/^I should see the attributes match their actual values$/) do
  begin
    expected_server_details = @expected_server_info.merge(data_for("default/#{@expected_server_info[:server_name]}"))
    expected_server_details.delete_if {|key, value| key == :username}
    expected_server_details.delete_if {|key, value| key == :password}
    $log.info("Expected server details: #{expected_server_details.to_s}")
    server_details = on_page(ServerListPage).get_server_details
    $log.info("Actual server details: #{server_details.to_s}")
    timestamp_regex = Regexp.new(data_for('regex_string')[:timestamp].to_s)
    server_details[:last_refresh].should match(timestamp_regex)
    server_details.delete(:last_refresh)
    server_details.should eq(expected_server_details)
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Server details verified.')
end

Then(/^I should be able to search for server "([^"]+)" with different attribute combinations$/) do |server_id, table|
  begin
    @expected_server_info = FigNewton.send("#{server_id}_server").to_hash
    server_list_page = on_page(ServerListPage)
    table.hashes.each do |entry|
      search_type = entry[:TYPE]
      $log.info("Server search type: #{search_type}")
      case search_type
        when 'Name only'
          server_list_page.search_server(@expected_server_info[:server_name])
        when 'IP only'
          server_list_page.search_server(nil, @expected_server_info[:ip])
        when 'Name and IP'
          server_list_page.search_server(@expected_server_info[:server_name], @expected_server_info[:ip])
        when 'Name and platform'
          server_list_page.search_server(@expected_server_info[:server_name], nil, @expected_server_info[:platform])
        when 'IP and platform'
          server_list_page.search_server(nil, @expected_server_info[:ip], @expected_server_info[:platform])
        when 'Name, IP and platform'
          server_list_page.search_server(@expected_server_info[:server_name], @expected_server_info[:ip], @expected_server_info[:platform])
        when 'Uppercase Name'
          server_list_page.search_server(@expected_server_info[:server_name].upcase)
        when 'RandomCase Name'
          server_list_page.search_server(@expected_server_info[:server_name].capitalize)
        else
          $log.info("The search type '#{search_type}' provided is not valid.")
          raise "Invalid search type '#{search_type}' requested!"
      end
      wait_for_spinner
      step %{I should see server #{server_id} listed in the table}
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

Then(/^I should be able to search for servers with partial search text$/) do |table|
  begin
    server_list_page = on_page(ServerListPage)
    table.hashes.each do |entry|
      search_type = entry[:TYPE]
      $log.info("Server search type: #{search_type}")
      case search_type
        when 'Partial Hostname'
          search_data = data_for('view_onboarded_servers/partial_hostname')
          server_list_page.search_server(search_data[:input_hostname_value])
          wait_for_spinner
          server_list_page.get_all_server_names_in_table.should =~ search_data[:output_list].split(',')
        when 'Partial IP'
          search_data = data_for('view_onboarded_servers/partial_ip')
          server_list_page.search_server(nil, search_data[:input_ip_value])
          wait_for_spinner
          server_list_page.get_all_server_names_in_table.should =~ search_data[:output_list].split(',')
        when 'Partial Hostname and Partial IP'
          search_data = data_for('view_onboarded_servers/partial_hostname_partial_ip')
          server_list_page.search_server(search_data[:input_hostname_value], search_data[:input_ip_value])
          wait_for_spinner
          server_list_page.get_all_server_names_in_table.should =~ search_data[:output_list].split(',')
        else
          $log.info("The search type '#{search_type}' provided is not valid.")
          raise "Invalid search type '#{search_type}' requested!"
      end
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end


## Negative

Then(/^I should see the warning message "([^"]+)" appears when searching for server "([^"]+)" with invalid attributes$/) do |message, server_id, table|
  begin
    @expected_server_info = FigNewton.send("#{server_id}_server").to_hash
    server_list_page = on_page(ServerListPage)
    table.hashes.each do |entry|
      selection_type = entry[:TYPE]
      $log.info("Server selection type: #{selection_type}")
      case selection_type
        when 'Fake name only'
          server_list_page.search_server(Faker::Internet.domain_name)
        when 'Fake IP only'
          server_list_page.search_server(nil, Faker::Internet.ip_v4_address)
        when 'Fake name and fake IP'
          server_list_page.search_server(Faker::Internet.domain_name, Faker::Internet.ip_v4_address)
        when 'Fake name and platform'
          server_list_page.search_server(Faker::Internet.domain_name, nil, @expected_server_info[:platform])
        when 'Fake IP and platform'
          server_list_page.search_server(nil, Faker::Internet.ip_v4_address, @expected_server_info[:platform])
        when 'Fake name, fake IP and platform'
          server_list_page.search_server(Faker::Internet.domain_name, Faker::Internet.ip_v4_address, @expected_server_info[:platform])
        else
          $log.info("The selection type '#{selection_type}' provided is not valid.")
          raise "Invalid selection type '#{selection_type}' requested!"
      end
      wait_for_spinner
      expect(on_page(ServerListPage).no_record_message_shown?(message)).to be true
      $log.info("Warning message '#{message}' appeared on the webpage.")
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end

