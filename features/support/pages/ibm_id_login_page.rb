class IBMIdLoginPage
  include PageObject
  include DataMagic
  include FigNewton

  def initialize_page
    # gets called at end of page_object initialize
  end

  text_field(:username, id: 'username', type: 'text')
  link(:continue, class: 'button', text: /Continue/)
  link(:switch_user, text: /Use a different IBMid or email/)

  def login_with(username, password)
    self.switch_user_element.visible? ? switch_user : ()
    self.username = username
    sleep 1
    continue
    text_field_element(id: 'password').when_present.value = password
    link_element(id: 'signinbutton').when_present.click
    # button_element(id: 'confirm-btn').when_present.click
    # appearance of left-menu indicates a successful log-in
    @browser.div(class: 'left-menu').wait_until_present
  end

  def login_as(user_role)
    user_info = FigNewton.send("#{user_role.downcase}_login").to_hash
    self.switch_user_element.visible? ? switch_user : ()
    self.username_element.when_present
    self.username = user_info[:username]
    sleep 1
    continue
    text_field_element(id: 'password').when_present.value = user_info[:password]
    link_element(id: 'signinbutton').when_present.click
    # button_element(id: 'confirm-btn').when_present.click
    # appearance of left-menu indicates a successful log-in
    @browser.div(class: 'left-menu').when_present
  end

end