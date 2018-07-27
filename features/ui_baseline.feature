Feature: SLA UI Baselines
  As an SLA user
  I want to carry out basic user interactions like "log in" or "view user information" etc.
  So I know the baseline functions are working properly

  Background: SLA UI - Open up welcome splash page
    Given I opened up the welcome splash page of SLA UI

# +++++++++++++++++++++++ Positive Scenarios +++++++++++++++++++++++ #

  # [Nov-13th] Ruifeng Ma: as a security measure, no EE API gets called prior to authentication. Hence no more build information available here.
#  @welcome @positive @bvt
#  Scenario: Check displayed information on welcome page
#    When I click on the application information icon
#    Then I should see the build information matches the actual release

  @login @positive @bvt
  Scenario Outline: Log in and check user and build information
    When I am logged into the SLA UI as a <USER_ROLE>
    And I click on the application information icon
    Then I should see the build information matches the actual release
    And I click on the user information icon
    Then I should see the user information matches current <USER_ROLE>
    And I log out
    Examples:
      | USER_ROLE       |
      | Requester       |
      | Executor        |
      | Approver        |
      | Onboarder       |

# ----------------------- Negative Scenarios ----------------------- #

   # [Dec-08-2017] Ruifeng Ma: no longer needed with IBMid authentication enabled
#  @login @negative @bvt
#  Scenario: Log in with invalid users
#    Given I navigated to the login page of SLA UI
#    Then I should see error messages pop up with invalid login attempts
#      | USER_ROLE                | ERROR_MESSAGE                                                           |
#      | faker                    | Invalid username and password                                           |
#      | insufficient_access_user | Insufficient group access.\nPlease contact your group admin for access. |
#      | empty                    | Invalid username and password                                           |
#      # | wrong_password           | Unable to verify username and password:\nYour LDAP appears to have been nullified due to either revocation or expiration (probably the latter).\nPlease contact your LDAP admin to correct the issue.     |
#      | wrong_password           | Invalid username and password                                           |
