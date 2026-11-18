Feature: ECO Ad Hoc Financial Search API and OpenIG test

  Reference: <JIRA_URL>/browse/ITAPPSIT-4305

  Background:
    Given I start with an empty context

    # ── Atlas Business Role & Org Access Tests (OpenIG / 200 and 403 Forbidden) ──

  Scenario Outline: OpenIG Business Role and Org Access Validation
    Given I start with an empty context
    And I log in to Atlas v4 as "<user_key>" and store the enoc_session
    #ECO dev env - use this org id
    And I set the search query parameter id to "36188949-d6ad-49a0-9c9e-426a1de57ad1" and id_type to "ORG"
    #ECO preprd env - use this org id
    #And I set the search query parameter id to "cad9f99e-0dd3-4934-98b1-40f812e9dbb5" and id_type to "ORG"
    And I include valid enoc_session header
    And I omit the Authorization header
    And I expect the next API call to return a status code of <expected_status> and message of "<expected_message>"
    When I POST to the external adhoc financial search endpoint
    Then the expected status should be returned

    Examples:
      | user_key                                      | expected_status | expected_message |
      | user_with_access                              | 200             | OK               |
      | user_org_access_no_dr_financial_role_access   | 403             | Forbidden        |
      | user_no_access_at_all                         | 403             | Forbidden        |
