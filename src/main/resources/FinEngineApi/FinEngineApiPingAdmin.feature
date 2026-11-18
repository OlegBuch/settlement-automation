Feature: Feature tests for FinEngine Api

  Reference: <JIRA_URL>/browse/ITAPPSIT-4185

  Scenario Outline: GET ping returns 401 when ENOC session is missing (<role>)
    Given I start with an empty context
    And I log in as a settlement API <role>
    And I do not send enoc_session
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET finEngine ping
    Then the expected status should be returned

    Examples:
      | role  |
      | admin |
      | user  |


  Scenario Outline: GET ping returns 401 when API key is missing (<role>)
    Given I start with an empty context
    And I log in as a settlement API <role>
    And I do not send an API key
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET finEngine ping
    Then the expected status should be returned

    Examples:
      | role  |
      | admin |
      | user  |


  Scenario Outline: GET ping returns 401 when ENOC session is invalid (<role>)
    Given I start with an empty context
    And I log in as a settlement API <role>
    And I send an invalid enoc_session
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET finEngine ping
    Then the expected status should be returned

    Examples:
      | role  |
      | admin |
      | user  |


  Scenario Outline: GET ping returns 401 when API key is invalid (<role>)
    Given I start with an empty context
    And I log in as a settlement API <role>
    And I send an invalid API key
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET finEngine ping
    Then the expected status should be returned

    Examples:
      | role  |
      | admin |
      | user  |


  Scenario Outline: GET ping returns 401 when both auth headers are missing (<role>)
    Given I start with an empty context
    And I log in as a settlement API <role>
    And I do not send an API key
    And I do not send enoc_session
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET finEngine ping
    Then the expected status should be returned

    Examples:
      | role  |
      | admin |
      | user  |


  Scenario Outline: GET ping returns 200 for valid auth (<role>)
    Given I start with an empty context
    And I log in as a settlement API <role>
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I call GET finEngine ping
    Then the expected status should be returned

    Examples:
      | role  |
      | admin |
      | user  |