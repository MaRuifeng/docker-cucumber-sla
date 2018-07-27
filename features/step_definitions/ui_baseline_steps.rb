## Positive: log in, build and user information scenarios

When(/^I click on the application information icon$/) do
  begin
    @build_info = get_build_info
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("Build info: #{@build_info}")
end

Then(/^I should see the build information matches the actual release$/) do
  begin
    # build_info_reg = /[0-9]{2}\.[0-9]\.[0-9]{8}-[0-9]{4}\.[0-9]+\z/
    # expected_build_info = ENV['APP_BUILD'].match(build_info_reg).to_s
    expected_build_info = "UI: #{ENV['APP_BUILD']}"
    @build_info.should eq(expected_build_info)
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Build info verified.')
end

When(/^I am logged into the SLA UI as a ([^"]+)$/) do | user_role|
  step %{I am logged into the SLA UI as a "#{user_role}"}
end

When(/^I click on the user information icon$/) do
  begin
    on_page(MainPage) do
      @user_info = get_user_info
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info("User info: #{@user_info.to_s}")
end

Then(/^I should see the user information matches current "([^"]*)"$/) do |user_role|
  $log.info("Current user role: #{user_role}")
  begin
    expected_user_info = FigNewton.send("#{user_role.downcase}_login").to_hash
    @user_info[:name].should eq(expected_user_info[:name])
    @user_info[:email].should eq(expected_user_info[:email])
    @user_info[:id].should eq(expected_user_info[:id])
    @user_info[:groups].split(',').should =~ expected_user_info[:groups].split(',')
    @user_info[:roles].split(',').should =~ expected_user_info[:roles].split(',')
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('User information verified.')
end

Then(/^I should see the user information matches current ([^"]+)$/) do |user_role|
  step %{I should see the user information matches current "#{user_role}"}
end

## Negative: log in, build and user information scenarios

Given(/^I navigated to the login page of SLA UI$/) do
  begin
    # on_page(SplashPage).get_started
    on_page(LoginPage)
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
  $log.info('Successfully landed on the login page.')
end

Given(/^I should see error messages pop up with invalid login attempts$/) do |table|
  begin
    table.hashes.each do |entry|
      on_page(LoginPage) do |page|
        $log.info("Attempting to log in with: #{entry[:USER_ROLE]}")
        page.login_as(entry[:USER_ROLE])
        wait_for_spinner
        error_msg = page.get_error_msg
        $log.info("Displayed error: #{error_msg}")
        error_msg.should eq(entry[:ERROR_MESSAGE])
      end
    end
  rescue Exception => error
    $log.error("#{error.class}: #{error.message}")
    raise
  end
end