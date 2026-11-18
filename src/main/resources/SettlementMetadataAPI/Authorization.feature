Feature: Settlement Metadata API authorization

  BDAP-1811: settlement metadata api authorization via Atlas resource

  All scenarios use the productrules endpoint.  Alessandro confirmed that authorization is handled above the endpoint level,
  therefore we do not have to verify every endpoint.

  Background:
    Given I start with an empty context
    And I want to log all API requests


  Scenario: No enoc_session or API key passed

    Given I do not send an API key
    And I do not send enoc_session
    And I expect the next API call to return a status code of 403 and details of "missing x-api-key header"
    When I call GET productrules
    Then the expected status should be returned


  Scenario: enoc_session but no API key

    Given I log in as a settlement API admin
    But I do not send an API key
    And I expect the next API call to return a status code of 403 and details of "missing x-api-key header"
    When I call GET productrules
    Then the expected status should be returned


  Scenario: API key but no enoc_session

    Given I send a valid API key
    But I do not send enoc_session
    And I expect the next API call to return a status code of 401 and details of "missing enoc_session header"
    When I call GET productrules
    Then the expected status should be returned


  Scenario: Invalid API key

    Given I log in as a settlement API admin
    But I send an invalid API key
    And I expect the next API call to return a status code of 403 and details of "not valid x-api-key header"
    When I call GET productrules
    Then the expected status should be returned


  Scenario: Invalid enoc_session

    Given I send a valid API key
    But I send an invalid enoc_session
    And I expect the next API call to return a status code of 401 and details of "You are not authenticated. Please login at login_url"
    When I call GET productrules
    Then the expected status should be returned


  Scenario: User does not have SETTLEMENT_ADMIN resource

    Given I send a valid API key
    But I log in as a settlement API user
    And I expect the next API call to return a status code of 200 and details of ""
    When I call GET productrules
    Then the expected status should be returned


  Scenario: User has SETTLEMENT_ADMIN resource

    Given I send a valid API key
    And I log in as a settlement API admin
    And I expect the next API call to return a status code of 200 and details of ""
    When I call GET productrules
    Then the expected status should be returned