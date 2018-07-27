class ServerListPage
  include PageObject
  include DataMagic
	include UIHelper

  def initialize_page
    # gets called at end of page_object initialize
  end

  text_field(:server_name_input, name: 'with_case_insensitive_partial_fqdn')
  text_field(:server_ip_input, name: 'with_partial_ip_address')
  select_list(:server_platform_selector, name: 'server_platform')
#  button(:search, class: 'search-button', text: /Search/) #Previous Search Button
  link(:search, :class => "server_detail_search_action_btn")

  table(:server_list, id: 'serverDataList')
	
	#	This is possible from here - http://cheezyworld.com/2012/05/23/a-better-shovel/#comment-1040
	image(:action_link_image, :title => 'Initiate Request') #not clickable
	link(:action_link) { |page| page.action_link_image_element }
	
  # server detail labels
  span(:server_details, text: /Server Details/, class: 'server-details-level')
  div(:server_name, text: /Server Name/, class: 'label')
  div(:short_name, text: /Short Name/, class: 'label')
  div(:ip, text: /IP Address/, class: 'label')
  div(:memory, text: /Memory/, class: 'label')
  div(:cpu_count, text: /Number of CPU/, class: 'label')
  div(:cpu_type, text: /CPU Type/, class: 'label')
  div(:server_platform, text: /Platform/, class: 'label')
  div(:status, text: /Status/, class: 'label')
  div(:last_refresh, text: /Last Refresh/, class: 'label')


  def search_server(name = nil, ip = nil, platform = nil)
    server_name_input_element.when_present
    server_ip_input_element.when_present
    server_platform_selector_element.when_present
    search_element.when_present
    name.nil? ? (self.server_name_input = '') : (self.server_name_input = name)
    ip.nil? ? (self.server_ip_input = '') : (self.server_ip_input = ip)
    platform.nil? ? (self.server_platform_selector = 'Select') : (self.server_platform_selector = platform)
    search_element.when_present.click
  end
	

  def init_server_request(server_name)
#    server_list_element[server_name]['Actions'].link_element().click
		action_link_element.when_present.click
  end

#	def select_server(server_name = nil, ip = nil, platform = nil)
#		search_server(server_name, ip, platform)
#		# Not working on my system
#		# server_list_element[server_name]['Actions'].link_element().click
#		init_server_request(server_name)
#	end
	
  def get_server_info_in_row(server_name)
    server_info = Hash.new
    server_info[:server_name] = server_list_element[server_name]['Server name'].text
    server_info[:ip] = server_list_element[server_name]['IP Address'].text
    server_info[:platform] = server_list_element[server_name]['Platform'].text
    server_info
  end

  def get_all_server_names_in_table
    server_names = Array.new
    server_list_element.each do |row|
      row.each do |cell|
        if !cell.attribute('class').nil? && cell.attribute('class') == 'details-control' # look for row containing data
          server_names.push(row['Server name'].text)
          break
        end
      end
    end
    server_names
  end

  def expand_server_details(server_name)
    row = server_list_element[server_name]
    unless row.attribute('class').include?('shown')
      row.cell_element(class: 'details-control').click
    end
    server_details_element.when_present
  end

  def collapse_server_details(server_name)
    row = server_list_element[server_name]
    if row.attribute('class').include?('shown')
      row.cell_element(class: 'details-control').click
    end
  end

  def get_server_details
    # only a single 'Server Details' section is shown at a time on the UI, so no argument given
    server_details = Hash.new
    server_details[:server_name] = self.server_name_element.parent.div_element(class: 'label-value').text
    server_details[:short_name] = self.short_name_element.parent.div_element(class: 'label-value').text
    server_details[:ip] = self.ip_element.parent.div_element(class: 'label-value').text
    server_details[:memory] = self.memory_element.parent.div_element(class: 'label-value').text
    server_details[:cpu_count] = self.cpu_count_element.parent.div_element(class: 'label-value').text
    server_details[:cpu_type] = self.cpu_type_element.parent.div_element(class: 'label-value').text
    server_details[:platform] = self.server_platform_element.parent.div_element(class: 'label-value').text
    server_details[:status] = self.status_element.parent.div_element(class: 'label-value').text
    server_details[:last_refresh] = self.last_refresh_element.parent.div_element(class: 'label-value').text
    server_details
  end

  def no_record_message_shown?(message)
    server_list_element.cell_element(text: Regexp.new(message)).when_present && true
  end

end