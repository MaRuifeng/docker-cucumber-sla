Feature: View onboarded servers
  As an SLA requester
  I want to check the server list
  So I know my servers are onboarded successfully and the information is displayed correctly

  Background: SLA UI - Navigate to the SSD work pane
    Given I opened up the welcome splash page of SLA UI
    And I am logged into the SLA UI as a "Requester"
    And I opened up the work pane for Self Service Delivery
    When I open up the SSD server page

# +++++++++++++++++++++++ Positive Scenarios +++++++++++++++++++++++ #

  @check_server @positive @bvt
  Scenario Outline: Check onboarded servers and their information
    And I search for server <ID> by its name
    Then I should see server <ID> listed in the table
    And I expand the details of server <ID>
    Then I should see the attributes match their actual values
    And I log out
    Examples:
      | ID              |
      | windows1        |
      | redhat1         |
      # | redhat2         |

  @search_server @positive @bvt
  Scenario: Check server search
    Then I should be able to search for server "windows1" with different attribute combinations
      | TYPE                  |
      | Name only             |
      | IP only               |
      | Name and IP           |
      | Name and platform     |
      | IP and platform       |
      | Name, IP and platform |
      | Uppercase Name        |
      | RandomCase Name       |
    And I log out

  @search_server @positive @partial_text @bvt
  Scenario: Check server search with partial text
    Then I should be able to search for servers with partial search text
      | TYPE                             |
      | Partial Hostname                 |
      | Partial IP                       |
      | Partial Hostname and Partial IP  |
    And I log out

  @select_server @positive @bvt
  Scenario Outline: Check onboarded servers and their information
    And I search for server <ID> by its name
    And I click on the action button to initiate a request for server <ID>
    And I log out
    Examples:
      | ID              |
      | windows1        |
      | redhat1         |


# ----------------------- Negative Scenarios ----------------------- #

  @search_server @negative @bvt
  Scenario: Search server with invalid attributes
    Then I should see the warning message "No records found!" appears when searching for server "windows1" with invalid attributes
      | TYPE                            |
      | Fake name only                  |
      | Fake IP only                    |
      | Fake name and fake IP           |
      | Fake name and platform          |
      | Fake IP and platform            |
      | Fake name, fake IP and platform |
    And I log out
