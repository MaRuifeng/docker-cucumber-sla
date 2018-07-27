class LoginPage
  include PageObject
  include DataMagic
  include FigNewton

  def initialize_page
    # gets called at end of page_object initialize
  end

  page_url("#{FigNewton.base_url}")

  text_field(:username, id: 'username', type: 'text')
  text_field(:password, id: 'password', type: 'password')
  # button(:login, value: 'login')
  button(:login, class: 'login_input_field')
  div(:login_error, id: 'login-error')

  def login_with(username, password)
    self.username = username
    self.password = password
    login
    # appearance of left-menu indicates a successful log-in
    @browser.div(class: 'left-menu').wait_until_present
  end

  def login_as(user_role)
    self.username_element.when_present
    self.password_element.when_present
    populate_page_with FigNewton.send("#{user_role.downcase}_login").to_hash
    login
    # appearance of left-menu indicates a successful log-in
    @browser.div(class: 'left-menu').when_present
  end

  def get_error_msg
    self.login_error_element.when_present
    login_error
  end
end
