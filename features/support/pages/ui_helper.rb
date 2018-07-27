# Commonly used methods across different page objects should be included in
# this module, rather than duplicating them in various page objects.

# Generally these are methods that are supported by the watir-webdriver only, methods
# supported by the page-object gem need to be defined in respective page objects.

# Initiated By: ruifengm@sg.ibm.com
# Date: 2017-Apr-20


module UIHelper
  include DataMagic
  include FigNewton

	def set_emergency
		sleep 1 #wait till the emergency button settle down. This is needed because of the re-alignment of the button when the CSS kicks in on this element
		@browser.button(id: 'emgedit').when_present.click
		@browser.label(for: 'f-option').when_present.click
		$log.info("Set Emergency option")
		@browser.button(id: 'emgupdate').when_present.click
	end
	
	def review_bundle
		@browser.div(class: 'mr-col').div(id: 'bundle_content_btn').button(class: 'bundleReviewBtn').when_present.click # There are 2 btns with the same class, hence the parent div filter
		wait_for_spinner
		@request_id = @browser.div(class: 'showallimg').span.span.text
		@request_id #return request id
	end
	
	def submit_bundle
		@browser.div(id: 'review_btn').button(class: 'bundle_sumbit_btn').when_present.click
    wait_for_spinner
		@browser.button(id: 'NS_okButton').when_present.click
	end
		
	def select_confirmation
		@browser.button(id: 'NS_okButton').when_present.click
	end
	
	def validate_error_popup msg
		if @browser.p(:id => 'NS_okDialogMessage').text.include? msg then
			$log.info "Error Message contains #{msg}"
			select_confirmation #Select Confirmation
		else
			$log.error "Error Message DOES NOT contain #{msg}, instead says #{msg}"
		end
  end

  # def verify_successful_execution request_id
  #   wait_for_spinner
  #   @browser.link(text: request_id).click
  #   wait_for_spinner
  #   @browser.div(class: 'showallimg').when_present.click
		# begin
		# 	if @browser.span(class: 'reqstatus').parent.text.include? "Executed Successfully" then
		# 		$log.info("Status changed to Executed Successfully")
		# 	end
		# 	sleep(20) #explicit wait
		# 	@browser.refresh #refresh the browser to see if the change request has executed successfully
		# end until @browser.span(class: 'reqstatus').parent.text.include? "Executed Successfully"
  # end
			
  def wait_for_spinner
    begin
      spinner = @browser.div(id: 'opaqueOverlay')
      Watir::Wait.until(20, "Spinner #{spinner.attribute_value('class')} is still visible. Page is loading...") do
        !spinner.present?
      end
    rescue Watir::Exception::UnknownObjectException => error
      $log.error("Rescued exception #{error.class}: #{error.message}")
      $log.info("Unable to locate the spinner. Perhaps it's gone. Proceed...")
    end

  end
	
	def wait_for_select_option element, select_options, option
		# This is in WIP state. Please uncomment the commented lines to debug - Nikhil Patil
		Watir::Wait.until(5, "Select Option #{option} not present") do
			avaialable_options = element.options.map! { |o| o.text }
			if avaialable_options.include? option then
				$log.info "Available Element Options #{avaialable_options}"
				avaialable_options.include? option
			else
				sleep 1
			end
    end
	end
	
  def get_build_info
    build_icon = @browser.div(class: 'ssd-header').when_present.li(class: 'buildInformation').when_present
    Watir::Wait.until(20, "Build information icon #{build_icon.attribute_value('class')} is not visible to click.") do
      build_icon.a.visible?
    end
    sleep 1
    build_icon.a.click
    build_icon.label.when_present.text.gsub('Build: ', '')
  end

  def get_user_info
    user_info = Hash.new
    drop_user_panel do |user_panel|
      user_panel.div(class: 'profile-info').labels.each do |label|
        label.text.include?('Name') ? (user_info[:name] = label.text.gsub('Name : ', '')) : ()
        label.text.include?('Email') ? (user_info[:email] = label.text.gsub('Email : ', '')) : ()
        label.text.include?('ID') ? (user_info[:id] = label.text.gsub('ID: ', '')) : ()
      end
      user_panel.div(class: 'groups-roles').a.when_present.click
      sleep 0.5 # for tags to load text
      group_list = ''
      user_panel.div(class: 'groups-roles-content').label(class: 'groups').when_present.elements(:tag_name => 'tag').each do |tag|
        group_list = group_list + ',' + tag.text
      end
      user_info[:groups] = group_list[1..-1] # remove first comma
      role_list= ''
      user_panel.div(class: 'groups-roles-content').label(class: 'roles').when_present.elements(:tag_name => 'tag').each do |tag|
        role_list = role_list + ',' + tag.text
      end
      user_info[:roles] = role_list[1..-1] # remove first comma
    end
    user_info
  end

  def log_out
    drop_user_panel do |user_panel|
      user_panel.a(class: 'logout').when_present.click
    end
    confirm_dialog = @browser.div(id: 'ibm-overlaywidget-NS_OKCancelOverlay')
    confirm_dialog.button(id: 'NS_okCancelOKButton').when_present.click
    # Watir::Wait.until(20, 'User information panel is still visible. Log out failed.') do
    #   !@browser.div(class: 'ssd-header').when_present.li(class: 'userInformation').present?
    # end
  end

  private

  def drop_user_panel
    user_panel = @browser.div(class: 'ssd-header').when_present.li(class: 'userInformation').when_present
    Watir::Wait.until(20, "User information icon #{user_panel.attribute_value('class')} is not present to click.") do
      user_panel.a.present?
    end
    overlay_present? ? (raise "Element #{user_panel.attribute_value('class')} blocked by overlay.") : user_panel.a.when_present.click # expand
    yield user_panel
    overlay_present? ? () : user_panel.a.when_present.click # collapse
  end

  def overlay_present?
    flag = false
    @browser.divs(class: 'ibm-common-overlay').each do |div|
      if div.present?
        flag = true
        break
      end
    end
    flag
  end

end
