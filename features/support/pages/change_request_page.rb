class ChangeRequestPage
    include PageObject
    include UIHelper

    div(:show_dropdown_div, :class => "ibm-drf-dropdown-menu-action-div")
	table(:mssql_database_table, :id => "test1table")
	button(:add_to_bundle_button, :id => "addOracleDbRestartChangeToBundle")
	button(:select_success_button, :id => "NS_okButton")
	
	def initialize_page
		# gets called at end of page_object initialize
	end

	def select_action_on_item_common action, item
		Watir::Wait.until(3, "Table took more than 3 seconds to load") do
			@browser.table(:id => "test1table").present?
		end
		Watir::Wait.until(3, "Table Data took more than 3 seconds to load") do
			@browser.table(:id => "test1table").rows[1].present?
		end
		show_dropdown_div_element.when_present
		mssql_database_table_element.each do |row, index|
			if row.text.include? item 
				$log.info("Found row with #{item}")
				row.div_element(:class => "ibm-drf-dropdown-menu-action-div").when_present.click
				row.list_item_element(:text => action).when_present.click
				break
			end
		end
	end

	def add_change_request_to_bundle_common
		add_to_bundle_button
		wait_for_spinner
	end
end