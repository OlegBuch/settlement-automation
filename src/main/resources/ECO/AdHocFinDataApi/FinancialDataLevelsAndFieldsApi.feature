Feature: ECO Ad Hoc Financial Levels API

  Reference: <JIRA_URL>/browse/ITAPPSIT-4231

  Background:
    Given I start with an empty context
    And I am trying to log in as an ECO admin


  # ── GET /api/v1/adhoc-financial/levels ──

  Scenario: GET all adhoc financial levels returns 200
    When I GET all adhoc financial levels
    Then the adhoc financial levels list should be returned

  Scenario: GET all adhoc financial levels fails with 401 if no authentication is sent
    Given I do not include ECO credentials
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all adhoc financial levels
    Then the expected status should be returned

  Scenario: GET all adhoc financial levels fails with 401 if password is missing
    Given I include ECO credentials with username only
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all adhoc financial levels
    Then the expected status should be returned

  Scenario: GET all adhoc financial levels fails with 401 if username is missing
    Given I include ECO credentials with password only
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all adhoc financial levels
    Then the expected status should be returned

  Scenario: GET all adhoc financial levels fails with 401 if authentication token is invalid
    Given I include invalid ECO credentials
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all adhoc financial levels
    Then the expected status should be returned

  Scenario: GET all adhoc financial levels fails with 403 if ADHOC_FINANCIAL_API_ADMIN permission is missing
    Given I log in as an ECO user without ADHOC_FINANCIAL_API_ADMIN permission
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET all adhoc financial levels
    Then the expected status should be returned

  # ── GET /api/v1/adhoc-financial/levels/{level_uuid}/fields ──

  Scenario: GET fields for a valid level UUID returns 200
    When I GET all adhoc financial levels
    Given I set the context level UUID to a valid flex level UUID
    When I GET the fields for the current level
    Then the level fields response should be returned

  Scenario: GET fields returns 404 if level UUID does not exist
    Given I set the context level UUID to "00000000-0000-0000-0000-000000000000"
    And I expect the next API call to return a status code of 404 and details of "level_uuid does not exist"
    When I GET the fields for the current level
    Then the expected status should be returned

  Scenario: GET fields returns 400 if level UUID does not exist
    Given I set the context level UUID to "1"
    And I expect the next API call to return a status code of 400 and details of "Failed to convert value"
    When I GET the fields for the current level
    Then the expected status should be returned

  Scenario: GET fields returns 400 if level UUID does not exist
    Given I set the context level UUID to "Test"
    And I expect the next API call to return a status code of 400 and details of "Failed to convert value"
    When I GET the fields for the current level
    Then the expected status should be returned

  Scenario: GET fields fails with 401 if no authentication is sent
    When I GET all adhoc financial levels
    Given I set the context level UUID to a valid flex level UUID
    And I do not include ECO credentials
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET the fields for the current level
    Then the expected status should be returned

  Scenario: GET fields fails with 401 if password is missing
    When I GET all adhoc financial levels
    And I set the context level UUID to a valid flex level UUID
    And I include ECO credentials with username only
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET the fields for the current level
    Then the expected status should be returned

  Scenario: GET fields fails with 401 if username is missing
    When I GET all adhoc financial levels
    And I set the context level UUID to a valid flex level UUID
    And I include ECO credentials with password only
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET the fields for the current level
    Then the expected status should be returned

  Scenario: GET fields fails with 403 if ADHOC_FINANCIAL_API_ADMIN permission is missing
    When I GET all adhoc financial levels
    And I set the context level UUID to a valid flex level UUID
    And I log in as an ECO user without ADHOC_FINANCIAL_API_ADMIN permission
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET the fields for the current level
    Then the expected status should be returned
