class BPMLoginPage
  include PageObject
  include DataMagic
  include FigNewton

  def initialize_page
    # gets called at end of page_object initialize
  end

  page_url("#{FigNewton.bpm_base_url}")

  text_field(:username, id: 'username', type: 'text')
  text_field(:password, id: 'password', type: 'password')
  button(:login, type: 'submit')
	div(:user_dropdown_div, id: 'processPortalUserDropdown')
	cell(:logout_cell, :text => 'Logout')

  def login_with(username, password)
    self.username = username
    self.password = password
    login
    # appearance of processPortalBanner indicates a successful log-in
    @browser.div(class: 'processPortalBanner').wait_until_present
  end

  def login_as(user_role)
    self.username_element.when_present
    self.password_element.when_present
    populate_page_with FigNewton.send("#{user_role.downcase}_login").to_hash
    login
    # appearance of processPortalBanner indicates a successful log-in
    @browser.div(class: 'processPortalBanner').wait_until_present
  end
	
	def logout
		user_dropdown_div_element.when_present.click
#		sleep 3
		logout_cell_element.when_present.click	
		sleep 3 #wait till the user is logged out properly. If absent, the next step of navigating to SLA UI fails.
	end
end