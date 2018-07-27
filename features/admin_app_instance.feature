Feature: Configure Automation Provider Proxy instances
  As an SLA system admin
  I need to be able to configure the Automation Provider Proxy instances
  So my EE server is properly supported

  Background: SLA UI - Navigate to the SSD work pane
    Given I opened up the welcome splash page of SLA UI
    And I am logged into the SLA UI as an "Admin"
    And I opened up the work pane for SSD Admin
    When I open up the Automation Provider Proxy Instances page

# +++++++++++++++++++++++ Positive Scenarios +++++++++++++++++++++++ #

  @check_existing_providers @positive
  Scenario Outline: Check configured providers and their information
    Then I should see a provider of type <TYPE> and fqdn <FQDN> listed in the table
    And I click the show button to get the details of the provider of fqdn <FQDN>
    Then I should see the provider attributes match the actual values
    And I log out
    Examples:
      | TYPE         | FQDN                         |
      | hmc          | dwinhmc.dub.usoh.ibm.com     |
      | vmware       | 9.30.80.124                  |


  @add @positive
  Scenario Outline: Add a new provider
    And I add a new provider of type <TYPE> and fqdn <FQDN>
    Then I should see that a new provider of type <TYPE> and fqdn <FQDN> is successfully added
    And I log out
    Examples:
      | TYPE      | FQDN                          |
      # | hmc       | dwinhmc.dub.usoh.ibm.com      |
      | hmc       | foobar                        |
      # | vmware    | 9.30.80.124                   |
      | vmware    | foobar                        |

  @delete @positive
  Scenario Outline: Delete an existing provider
    And I delete an existing provider of type <TYPE> and fqdn <FQDN>
    Then I should see that the existing provider of type <TYPE> and fqdn <FQDN> is successfully deleted
    And I log out
    Examples:
      | TYPE      | FQDN                          |
      # | hmc       | dwinhmc.dub.usoh.ibm.com      |
      | hmc       | foobar                        |
      # | vmware    | 9.30.80.124                   |
      | vmware       | foobar                        |


# ----------------------- Negative Scenarios ----------------------- #

