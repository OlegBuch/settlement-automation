Feature: Feature tests for settlement creator

  Reference: <JIRA_URL>/browse/ITAPPSIT-4055

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  Scenario: GET ping returns 401 when ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET settlement creator ping
    Then the expected status should be returned

  Scenario: GET ping returns 401 when API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET settlement creator ping
    Then the expected status should be returned

  Scenario: GET ping returns 401 when ENOC session is invalid
    Given I send an invalid enoc_session
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET settlement creator ping
    Then the expected status should be returned

  Scenario: GET ping returns 401 when API key is invalid
    Given I send an invalid API key
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET settlement creator ping
    Then the expected status should be returned

  Scenario: GET ping returns 401 when both the ENOC session and the API key are missing
    Given I do not include the API key header
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET settlement creator ping
    Then the expected status should be returned

  Scenario: GET ping returns 200
    When I call GET settlement creator ping
    And I expect the next API call to return a status code of 200 and message of "OK"
    Then the expected status should be returned

Scenario: GET ping returns 403 if user does not have either SETTLEMENT_ADMIN or SETTLEMENT_USER roles
    Given I log in as a settlement API NO_STM_ROLES_USER
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I call GET settlement creator ping
    Then the expected status should be returned
