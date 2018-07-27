class RequestListPage
  include PageObject
  include DataMagic
  include UIHelper

  def initialize_page
    # gets called at end of page_object initialize
  end

  table(:request_list, id: 'requestDataList')
  link(:search, id: 'request_search_btn')
  link(:clear, id: 'request_clear_search_btn')

  text_field(:request_id_input, name: 'id')
  text_field(:bundle_id_input, name: 'change_request_bundle')
  text_field(:server_name_input, name: 'for_server_with_case_insensitive_partial_fqdn')
  select_list(:request_status_selector, name: 'with_status_key_in')


  def clear_search
    clear_element.when_present.click
  end

  def search_for_request_by_id request_id
    request_id_input_element.when_present
    request_id.nil? ? (self.request_id_input = '') : (self.request_id_input = request_id)
    search_element.when_present.click
  end

  def get_request_info_in_row request_id
    request_info = Hash.new
    request_info[:id] = request_id
    request_info[:bundle_id] = request_list_element[request_id]['Bundle ID'].text
    request_info[:server_name] = request_list_element[request_id]['Server Name'].text
    request_info[:change_type] = request_list_element[request_id]['Type'].text
    request_info[:action] = request_list_element[request_id]['Action'].text
    request_info[:status] = request_list_element[request_id]['Status'].text
    request_info[:creation_time] = request_list_element[request_id]['Created on'].text
    request_info
  end

  def get_current_execution_status request_id
    search_for_request_by_id request_id
		wait_for_spinner
		request_info = get_request_info_in_row request_id
		# get current status
		$log.info("Current Status of Change Request: #{request_info[:status].to_s}")
		request_info[:status].to_s
  end

  def open_request_bundle_details request_id
    search_for_request_by_id request_id
    wait_for_spinner
    link_element(text: request_id).click
    wait_for_spinner
  end

	def get_final_execution_status request_id
    progress_status_array = Array.new
    progress_status_array.push DRAFT
    progress_status_array.push PENDING_EXECUTION
    progress_status_array.push PENDING_APPROVAL
    progress_status_array.push PENDING_MODIFICATION
    progress_status_array.push EXECUTING
    progress_status_array.push SUBMITTED

    $log.info("Progress statuses: #{progress_status_array.to_s}")

    execution_status = nil
    Watir::Wait.until(MAX_EXECUTION_WAIT, "Request #{request_id} not finished after waiting for #{MAX_EXECUTION_WAIT} seconds.") do
      sleep 5 # time interval to perform the check
      search_for_request_by_id request_id
      wait_for_spinner
      request_info = get_request_info_in_row request_id
      unless progress_status_array.include?(request_info[:status].to_s)
        # execution finished
        $log.info("Finished request info: #{request_info.to_s}")
        execution_status = request_info[:status].to_s
      end
      clear_search
      wait_for_spinner
      !execution_status.nil?
    end
    execution_status
  end

end
