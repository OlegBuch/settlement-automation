Feature: ECO Ad Hoc Financial Search API

  Reference: <JIRA_URL>/browse/ITAPPSIT-4332

  Background:
    Given I start with an empty context
    And I log in to Atlas v4 as "user_with_access" and store the enoc_session

  # ── POST /api/v1/adhoc-financial/search ──

  Scenario: Valid request - all params and headers correct
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "ORG"
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

   Scenario: Missing enoc_session header
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "ORG"
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Empty enoc_session header value
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "ORG"
    And I provide an empty enoc_session header value
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Enoc_session headers present but empty
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "ORG"
    And I provide an empty enoc_session header value
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Missing id query parameter
    Given I omit the id query parameter
    And I set the search query parameter id_type to "ORG"
    And I expect the next API call to return a status code of 403 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Empty id query parameter value
    Given I provide an empty id query parameter value
    And I set the search query parameter id_type to "ORG"
    And I expect the next API call to return a status code of 403 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Malformed/non-UUID id value
    Given I set the search query parameter id to "12345-not-a-uuid" and id_type to "ORG"
    And I expect the next API call to return a status code of 403 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Non-existent (but valid-format) id
    Given I set the search query parameter id to "00000000-0000-0000-0000-000000000000" and id_type to "ORG"
    And I expect the next API call to return a status code of 403 and message of "OK"
    When I POST to the external adhoc financial search endpoint


  Scenario: Missing id_type query parameter
    Given I set the search query parameter id to "VALID_ORG_ID"
    And I omit the id_type query parameter
    And I expect the next API call to return a status code of 403 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Invalid id_type value (unsupported enum)
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "INVALID_TYPE"
    And I expect the next API call to return a status code of 403 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: SQL injection attempt in id parameter
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "' OR '1'='1"
    And I expect the next API call to return a status code of 403 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Extra/unexpected query parameter supplied
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "ORG"
    And I add an extra query parameter "extraParam" with value "test"
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Case-sensitivity check on id_type
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "org"
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: Duplicate id_type query parameters
    Given I set duplicate search query parameters with id "VALID_ORG_ID", id_type "ORG" and "USER"
    And I expect the next API call to return a status code of 400 and message of "Forbidden"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  # ── Pagination Edge Cases (400 Bad Request) ──

  Scenario: per_page parameter exceeds maximum allowed limit
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "ORG"
    And I add an extra query parameter "per_page" with value "900"
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: page parameter is zero
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "ORG"
    And I add an extra query parameter "page" with value "0"
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

  Scenario: page parameter is negative
    Given I set the search query parameter id to "VALID_ORG_ID" and id_type to "ORG"
    And I add an extra query parameter "page" with value "-1"
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned