Feature: Settlement item timebound authorization

  Background:
    Given I start with an empty context

  Scenario: Missing enoc_session is rejected
    Given I do not send enoc_session
    Given I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET settlement_item_timebound for id <uuid>
    Then the expected status should be returned

  Scenario: Invalid enoc_session is rejected
    Given I send an invalid enoc_session
    Given I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I call GET settlement_item_timebound for id <uuid>
    Then the expected status should be returned

  Scenario: Internal URL API key checks
    Given this scenario is only supported for the devtest environment
    And I log in as a settlement API admin

    Given I do not send an API key
    Given I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I call GET settlement_item_timebound for id <uuid>
    Then the expected status should be returned

    Given I send a valid API key
    Given I send an invalid API key
    Given I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I call GET settlement_item_timebound for id <uuid>
    Then the expected status should be returned
