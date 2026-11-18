Feature: ECO Ad Hoc Financial API

  Reference: <JIRA_URL>/browse/ITAPPSIT-4232
  Reference: <JIRA_URL>/browse/ITAPPSIT-4233

  Background:
    Given I start with an empty context
    And I am trying to log in as an ECO admin
    Given I log in as an ECO ECO_ADMIN and get session

  # ═══════════════════════════════════════════════════
  # POST SUCCESS SCENARIOS
  # ═══════════════════════════════════════════════════

  Scenario: Successful single-element insert - baseline valid body, no custom fields
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And the response should contain 1 inserted ids
    And I save the first inserted id from the response
    And I delete the adhoc financial record

  Scenario: multi-element insert (2 elements, each with 1 custom field)
    And I create an adhoc financial element with body
      | org_id          | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id         | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id      | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id      | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date      | 2020-08-19                           |
      | end_date        | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I create an adhoc financial element with body
      | org_id          | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id         | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id      | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id      | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date      | 2020-08-19                           |
      | end_date        | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And I delete all inserted records from the response

  Scenario: non-insert with multiple custom fields per element
    And I create an adhoc financial element with body
      | org_id             | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id            | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id         | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id         | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date         | 2020-08-19                           |
      | end_date           | 2035-08-19                           |
      | test_field_text    | ERR                                  |
      | test_field_number  | 123                                  |
      | test_field_boolean | true                                 |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Validation"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Successful insert with no custom fields present (baseline body as-is)
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And the response should contain 1 inserted ids
    And I save the first inserted id from the response
    And I delete the adhoc financial record

  Scenario: Successful insert with large batch (100 elements)
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add 100 baseline valid elements to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And the response should contain 100 inserted ids
    And I delete all inserted records from the response

  # ═══════════════════════════════════════════════════
  # POST NEGATIVE SCENARIOS (No cleanup needed)
  # ═══════════════════════════════════════════════════

  Scenario: All required fields missing simultaneously
    Given I set the raw adhoc financial payload to "[{}]"
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the raw adhoc financial payload
    Then the expected status should be returned

  Scenario: Multi-element array: 1 valid element + 1 element missing org_id
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I create an adhoc financial element with body
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: site_id exists in Flex but does not belong to given org_id
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 27e7f0f4-1e87-4a72-92e3-2969a0003180 |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: org_id exists in Flex but does not belong to user
    And I create an adhoc financial element with body
      | org_id     | b0b858ac-b501-488a-934b-9661024c119a |
      | site_id    | 27e7f0f4-1e87-4a72-92e3-2969a0003180 |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: org_id is malformed (not a valid UUID)
    And I create an adhoc financial element with body
      | org_id     | not-a-uuid                           |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: product_id does not exist
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 00000000-0000-0000-0000-000000000000 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: program_id does not exist
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 00000000-0000-0000-0000-000000000000 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: product_id does is invalid reference
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 00000000-0000 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: program_id is invalid reference
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 00000000-0000 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Custom field is not allowed
    And I create an adhoc financial element with body
      | org_id            | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id           | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id        | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id        | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date        | 2020-08-19                           |
      | end_date          | 2035-08-19                           |
      | unknown_field_xyz | ERR                                  |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Custom field name matches confirmed test field (test_field_text)
    And I create an adhoc financial element with body
      | org_id          | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id         | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id      | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id      | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date      | 2020-08-19                           |
      | end_date        | 2035-08-19                           |
      | test_field_text | ERR                                  |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Custom field"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Custom field value type mismatch - boolean field given non-boolean value
    And I create an adhoc financial element with body
      | org_id             | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id            | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id         | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id         | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date         | 2020-08-19                           |
      | end_date           | 2035-08-19                           |
      | test_field_boolean | yes                                  |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Missing ADHOC_FINANCIAL_API_ADMIN permission
    Given I log in as an ECO ECO_USER and get session
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 403 and message of "Missing"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Valid permission but no session/authentication at all
    Given I do not include ECO credentials
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 401 and message of "Missing"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Empty array as request body
    Given I set the adhoc financial payload to an empty array
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Request body is not an array (single object instead of array)
    Given I set the raw adhoc financial payload to "{\"org_id\":\"a85920a4-f1d4-41aa-8cdf-95f58382a8dc\",\"site_id\":\"00f4831a-877d-4926-8bf5-a21f54d0424e\",\"program_id\":\"5a4b321b-ef82-423f-9766-d65e53ff2f57\",\"product_id\":\"811931c6-5df0-4c3f-87b3-37e66c76d104\",\"start_date\":\"2020-08-19\",\"end_date\":\"2035-08-19\"}"
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the raw adhoc financial payload
    Then the expected status should be returned

  Scenario: start_date is after end_date
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2036-08-25                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: start_date is empty
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | empty                                |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: end_date is empty
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | empty                                |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: start_date/end_date malformed (not YYYY-MM-DD)
    And I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 08/19/2020                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

  Scenario: Duplicate custom field key within the same array element
    Given I set the raw adhoc financial payload to "[{\"org_id\":\"a85920a4-f1d4-41aa-8cdf-95f58382a8dc\",\"site_id\":\"00f4831a-877d-4926-8bf5-a21f54d0424e\",\"program_id\":\"5a4b321b-ef82-423f-9766-d65e53ff2f57\",\"product_id\":\"811931c6-5df0-4c3f-87b3-37e66c76d104\",\"start_date\":\"2020-08-19\",\"end_date\":\"2035-08-19\",\"test_field_text\":\"ERR\",\"test_field_text\":\"WARN\"}]"
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the raw adhoc financial payload
    Then the expected status should be returned

  Scenario: Response body verification - returned ids match count and order
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add 3 baseline valid elements to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And the response should contain 3 inserted ids
    And I delete all inserted records from the response

  Scenario Outline: POST - <field> is <condition>
    Given I create an adhoc financial element with body
      | org_id     | <org_id>     |
      | site_id    | <site_id>    |
      | program_id | <program_id> |
      | product_id | <product_id> |
      | start_date | <start_date> |
      | end_date   | <end_date>   |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned

    Examples: org_id null/missing
      | condition | org_id | site_id                              | program_id                           | product_id                           | start_date | end_date   |
      | null      | null   | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |
      | missing   |        | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |

    Examples: site_id null/missing
      | condition | org_id                               | site_id | program_id                           | product_id                           | start_date | end_date   |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | null    | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |         | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |

    Examples: program_id null/missing
      | condition | org_id                               | site_id                              | program_id | product_id                           | start_date | end_date   |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | null       | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e |            | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |

    Examples: product_id null/missing
      | condition | org_id                               | site_id                              | program_id                           | product_id | start_date | end_date   |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | null       | 2020-08-19 | 2035-08-19 |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |            | 2020-08-19 | 2035-08-19 |

    Examples: start_date null/missing
      | condition | org_id                               | site_id                              | program_id                           | product_id                           | start_date | end_date   |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | null       | 2035-08-19 |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 |            | 2035-08-19 |

    Examples: end_date null/missing
      | condition | org_id                               | site_id                              | program_id                           | product_id                           | start_date | end_date |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | null     |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 |          |


  Scenario Outline: POST - <field> is a random UUID that does not exist in Atlas
    Given I create an adhoc financial element with body
      | org_id     | <org_id>     |
      | site_id    | <site_id>    |
      | program_id | <program_id> |
      | product_id | <product_id> |
      | start_date | 2020-08-19   |
      | end_date   | 2035-08-19   |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of <status> and message of "<message>"
    When I POST the adhoc financial payload
    Then the expected status should be returned

    Examples: org_id does not exist
      | field   | org_id                               | site_id                              | program_id                           | product_id                           | status | message   |
      | org_id  | 3d5686b8-020c-45f0-b351-dcfec026592f | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 400    | Not Found  |

    Examples: site_id does not exist
      | field    | org_id                               | site_id                              | program_id                           | product_id                           | status | message   |
      | site_id  | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | e38dc93c-b3e7-4e2d-8414-450b8cd4b57c | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 400    | Not Found  |

    Examples: program_id does not exist
      | field       | org_id                               | site_id                              | program_id                           | product_id                           | status | message   |
      | program_id  | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 8fbb9c57-d03e-4cf4-9f0d-560fdca0a736 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 400    | Not Found  |

    Examples: product_id does not exist
      | field       | org_id                               | site_id                              | program_id                           | product_id                           | status | message   |
      | product_id  | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 1caa031b-6817-41bd-b89d-8576561ccaf8 | 400    | Not Found  |


  # ═══════════════════════════════════════════════════
  # CRUD SCENARIOS (GET / PUT / delete)
  # Every scenario builds its own baseline, tests it, and tears it down.
  # ═══════════════════════════════════════════════════

  Scenario: GET - Retrieve existing adhoc financial record
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I GET the adhoc financial record
    Then the expected status should be returned
    And the response should contain the adhoc financial data
    And I delete the adhoc financial record

  Scenario: GET - Retrieve non-existent record
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Failed to convert value"
    When I GET the adhoc financial record for id "00000000-0000-0000-0000-000000000000"
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: GET - Malformed ID in path
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I GET the adhoc financial record for id "not-a-uuid"
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: GET - Missing ADHOC_FINANCIAL_API_ADMIN permission
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    Given I log in as an ECO ECO_USER and get session
    And I expect the next API call to return a status code of 403 and message of "Missing"
    When I GET the adhoc financial record
    Then the expected status should be returned
    Given I log in as an ECO ECO_ADMIN and get session
    And I delete the adhoc financial record

  Scenario: GET - Missing Authorization header
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    Given I do not include ECO credentials
    And I expect the next API call to return a status code of 401 and message of "Missing"
    When I GET the adhoc financial record
    Then the expected status should be returned
    Given I log in as an ECO ECO_ADMIN and get session
    
  Scenario: GET - Retrieve soft-deleted record
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 204 and message of "OK"
    When I delete the adhoc financial record
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I GET the adhoc financial record
    Then the expected status should be returned

  Scenario: GET - Missing id segment in path
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Not Found"
    When I GET the adhoc financial record for id ""
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: GET - Method not allowed on adhoc financial path
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "'PATCH'"
    When I send a PATCH request to the adhoc financial record
    Then the expected status should be returned
    And I expect the next API call to return a status code of 204 and message of "No Content"
    And I delete the adhoc financial record

  Scenario: GET - SQL injection attempt in id path parameter
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I GET the adhoc financial record for id "'; DROP TABLE adhoc_financial; --"
    Then the expected status should be returned

   #PUT Scenarios

  Scenario: PUT - Update non-existent record
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Failed to convert"
    When I PUT the adhoc financial record for id "00000000-0000-0000-0000-000000000000" with body
      | test_field_text | ERR |
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Malformed ID in path
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record for id "not-a-uuid" with body
      | test_field_text | ERR |
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - start_date after end_date
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2036-08-25 |
      | end_date   | 2020-08-19 |
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Missing ADHOC_FINANCIAL_API_ADMIN permission
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    Given I log in as an ECO ECO_USER and get session
    And I expect the next API call to return a status code of 403 and message of "Missing"
    When I PUT the adhoc financial record with body
      | test_field_text | ERR |
    Then the expected status should be returned
    Given I log in as an ECO ECO_ADMIN and get session
    And I delete the adhoc financial record

  Scenario: PUT - Update org_id to non-existent Atlas org
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record with body
      | org_id | 00000000-0000-0000-0000-000000000000 |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Update site_id to non-existent Atlas site
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id | 00000000-0000-0000-0000-000000000000 |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Update site_id not belonging to org_id
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id | 11111111-1111-1111-1111-111111111111 |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Change only org_id to a new valid org, site_id unchanged
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 200 and message of "Validation"
    When I PUT the adhoc financial record with body
      | org_id | 36188949-d6ad-49a0-9c9e-426a1de57ad1 |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Change only site_id to a new valid site, org_id unchanged (Atlas not re-checked for org)
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 200 and message of "Validation"
    When I PUT the adhoc financial record with body
      | site_id    | 7c64a343-0aec-4b7e-bc43-329ea2c61cc6 |
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |

    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - new property in the body
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Validation"
    When I PUT the adhoc financial record with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
      | test_field_text | UNCHANGED_IDS                        |
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Empty body is a no-op
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "OK"
    When I PUT the adhoc financial record with an empty body
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Check updated value
    Given I create an adhoc financial element with body
      | org_id          | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id         | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id      | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id      | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date      | 2020-08-19                           |
      | end_date        | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I PUT the adhoc financial record with body
      | site_id    | 7c64a343-0aec-4b7e-bc43-329ea2c61cc6 |
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I GET the adhoc financial record
    Then the expected status should be returned
    And the custom field "site_id" should be "7c64a343-0aec-4b7e-bc43-329ea2c61cc6" in the response
    And I delete the adhoc financial record

  Scenario: PUT - Array body instead of object is rejected
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record with raw body "[{\"test_field_text\":\"ERR\"}]"
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Duplicate custom field keys in raw JSON body
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record with raw body "{\"test_field_text\":\"ERR\",\"test_field_text\":\"WARN\"}"
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: PUT - Malformed JSON body
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record with raw body "{test_field_text: ERR"
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario Outline: PUT - <field> is <condition>
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the adhoc financial record with body
      | org_id     | <org_id>     |
      | site_id    | <site_id>    |
      | program_id | <program_id> |
      | product_id | <product_id> |
      | start_date | <start_date> |
      | end_date   | <end_date>   |
    Then the expected status should be returned
    And I delete the adhoc financial record

    Examples: org_id null/missing
      | condition | org_id | site_id                              | program_id                           | product_id                           | start_date | end_date   |
      | null      | null   | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |
      | missing   |        | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |

    Examples: site_id null/missing
      | condition | org_id                               | site_id | program_id                           | product_id                           | start_date | end_date   |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | null    | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |         | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |

    Examples: program_id null/missing
      | condition | org_id                               | site_id                              | program_id | product_id                           | start_date | end_date   |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | null       | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e |            | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | 2035-08-19 |

    Examples: product_id null/missing
      | condition | org_id                               | site_id                              | program_id                           | product_id | start_date | end_date   |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | null       | 2020-08-19 | 2035-08-19 |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |            | 2020-08-19 | 2035-08-19 |

    Examples: start_date null/missing
      | condition | org_id                               | site_id                              | program_id                           | product_id                           | start_date | end_date   |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | null       | 2035-08-19 |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 |            | 2035-08-19 |

    Examples: end_date null/missing
      | condition | org_id                               | site_id                              | program_id                           | product_id                           | start_date | end_date |
      | null      | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 | null     |
      | missing   | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 2020-08-19 |          |

  Scenario Outline: PUT - <field> is a random UUID that does not exist in Atlas
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of <status> and message of "<message>"
    When I PUT the adhoc financial record with body
      | org_id     | <org_id>     |
      | site_id    | <site_id>    |
      | program_id | <program_id> |
      | product_id | <product_id> |
      | start_date | 2020-08-19   |
      | end_date   | 2035-08-19   |
    Then the expected status should be returned
    And I delete the adhoc financial record

    Examples: org_id does not exist
      | field   | org_id                               | site_id                              | program_id                           | product_id                           | status | message   |
      | org_id  | 3d5686b8-020c-45f0-b351-dcfec026592f | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 400    | Not Found  |

    Examples: site_id does not exist
      | field    | org_id                               | site_id                              | program_id                           | product_id                           | status | message   |
      | site_id  | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | e38dc93c-b3e7-4e2d-8414-450b8cd4b57c | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 400    | Not Found  |

    Examples: program_id does not exist
      | field       | org_id                               | site_id                              | program_id                           | product_id                           | status | message   |
      | program_id  | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 8fbb9c57-d03e-4cf4-9f0d-560fdca0a736 | 811931c6-5df0-4c3f-87b3-37e66c76d104 | 400    | Not Found  |

    Examples: product_id does not exist
      | field       | org_id                               | site_id                              | program_id                           | product_id                           | status | message   |
      | product_id  | a85920a4-f1d4-41aa-8cdf-95f58382a8dc | 00f4831a-877d-4926-8bf5-a21f54d0424e | 5a4b321b-ef82-423f-9766-d65e53ff2f57 | 1caa031b-6817-41bd-b89d-8576561ccaf8 | 400    | Not Found  |

  # DELETE scenarios

  Scenario: Delete - Soft delete existing record
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 204 and message of "OK"
    When I delete the adhoc financial record

  Scenario: Delete - Delete non-existent record
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Failed"
    When I delete the adhoc financial record for id "00000000-0000-0000-0000-000000000000"
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: Delete - Delete non-existent record
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 404 and message of "Adhoc financial"
    When I delete the adhoc financial record for id "1"
    Then the expected status should be returned
    And I delete the adhoc financial record


  Scenario: Delete - Malformed ID in path
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I delete the adhoc financial record for id "not-a-uuid"
    Then the expected status should be returned
    And I delete the adhoc financial record

  Scenario: Delete - Verify GET returns 404 after soft delete
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 204 and message of "OK"
    When I delete the adhoc financial record
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I GET the adhoc financial record
    Then the expected status should be returned

  Scenario: Delete - Missing ADHOC_FINANCIAL_API_ADMIN permission
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    Given I log in as an ECO ECO_USER and get session
    And I expect the next API call to return a status code of 403 and message of "Missing"
    When I delete the adhoc financial record
    Then the expected status should be returned
    Given I log in as an ECO ECO_ADMIN and get session
    And I delete the adhoc financial record

  Scenario: Delete - Missing Authorization header
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    Given I do not include ECO credentials
    And I expect the next API call to return a status code of 401 and message of "Missing"
    When I delete the adhoc financial record
    Then the expected status should be returned
    Given I log in as an ECO ECO_ADMIN and get session
    And I expect the next API call to return a status code of 401 and message of "Missing"
    And I delete the adhoc financial record

  Scenario: Delete - Delete already soft-deleted record
    Given I create an adhoc financial element with body
      | org_id     | a85920a4-f1d4-41aa-8cdf-95f58382a8dc |
      | site_id    | 00f4831a-877d-4926-8bf5-a21f54d0424e |
      | program_id | 5a4b321b-ef82-423f-9766-d65e53ff2f57 |
      | product_id | 811931c6-5df0-4c3f-87b3-37e66c76d104 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    When I POST the adhoc financial payload
    And I save the first inserted id from the response
    And I expect the next API call to return a status code of 204 and message of "OK"
    When I delete the adhoc financial record
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I delete the adhoc financial record
    Then the expected status should be returned

  Scenario: Delete - Missing id segment in path
    And I expect the next API call to return a status code of 400 and message of "Unexpected"
    When I delete the adhoc financial record for id ""
    Then the expected status should be returned

  Scenario: Delete - SQL injection attempt in id path parameter
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I delete the adhoc financial record for id "'; DROP TABLE adhoc_financial; --"
    Then the expected status should be returned


  Scenario: Add custom fields
    And this scenario is only supported for the preprd environment
    And I create an adhoc financial element with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a                                     |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
      | baseline_cost   | num: 12.111                 |
      | actual_cost     | num: 25.31                  |
      | co2_avoided     | num:11.1                   |
      | event_id        | DISP-2026-0901-01      |
      | currency        | EUR                    |
      | co2_mass_unit   | kg                     |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And the response should contain 1 inserted ids
    And I save the first inserted id from the response
    And I delete the adhoc financial record


  Scenario: Update with custom fields
    And this scenario is only supported for the preprd environment
    And I create an adhoc financial element with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
      And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And the response should contain 1 inserted ids
    And I save the first inserted id from the response
    When I PUT the adhoc financial record with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a                                     |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
      | baseline_cost   | num: 12.111                 |
      | actual_cost     | num: 25.31                  |
      | co2_avoided     | num:11.1                   |
      | event_id        | DISP-2026-0901-01      |
      | currency        | EUR                    |
      | co2_mass_unit   | kg                     |
    Then the expected status should be returned
    And the custom field "baseline_cost" should equal "12.111" in the response
    And the custom field "actual_cost" should equal "25.31" in the response
    And the custom field "co2_avoided" should equal "11.1" in the response
    And the custom field "event_id" should equal "DISP-2026-0901-01" in the response
    And the custom field "currency" should equal "EUR" in the response
    And the custom field "co2_mass_unit" should equal "kg" in the response
    And I expect the next API call to return a status code of 204 and message of "OK"
    And I delete the adhoc financial record

  Scenario: Incorrect add custom fields - EUR - 400
    And this scenario is only supported for the preprd environment
    And I create an adhoc financial element with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a                                     |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
      | baseline_cost   | num: 12.111                 |
      | actual_cost     | num: 25.31                  |
      | co2_avoided     | num:11.1                   |
      | event_id        | DISP-2026-0901-01      |
      | currency        | EUR1                    |
      | co2_mass_unit   | kg                     |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned


  Scenario: Incorrect update with custom fields - EUR - 400
    And this scenario is only supported for the preprd environment
    And I create an adhoc financial element with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And the response should contain 1 inserted ids
    And I save the first inserted id from the response

    Given I expect the next API call to return a status code of 400 and message of "Invalid"
    When I PUT the adhoc financial record with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a                                     |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
      | baseline_cost   | num: 12.111                 |
      | actual_cost     | num: 25.31                  |
      | co2_avoided     | num:11.1                   |
      | event_id        | DISP-2026-0901-01      |
      | currency        | EUR1                    |
      | co2_mass_unit   | kg                     |
    Then the expected status should be returned


  Scenario: Incorrect add custom field- kg - 400
    And this scenario is only supported for the preprd environment
    And I create an adhoc financial element with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a                                     |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
      | baseline_cost   | num: 12.111                 |
      | actual_cost     | num: 25.31                  |
      | co2_avoided     | num:11.1                   |
      | event_id        | DISP-2026-0901-01      |
      | currency        | EUR                    |
      | co2_mass_unit   | kg1                     |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the adhoc financial payload
    Then the expected status should be returned


  Scenario: Incorrect update with custom fields - kg - 400
    And this scenario is only supported for the preprd environment
    And I create an adhoc financial element with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
    And I add the current element to the adhoc financial payload
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the adhoc financial payload
    Then the expected status should be returned
    And the response should contain 1 inserted ids
    And I save the first inserted id from the response

    Given I expect the next API call to return a status code of 400 and message of "Invalid"
    When I PUT the adhoc financial record with body
      | org_id     | 3201d683-5301-433d-9796-f65749022451 |
      | site_id    | a98b20d9-9328-4fc3-9364-ed2863cdd8f8 |
      | operator_id | 357010cd-d52b-46d8-a413-5a3dcbff9d6a                                     |
      | program_id | c0640137-a701-4158-b77b-9505248d9175 |
      | product_id | 4c2cd0c5-ab3b-4a71-90ad-94d85f0a9aa0 |
      | start_date | 2020-08-19                           |
      | end_date   | 2035-08-19                           |
      | baseline_cost   | num: 12.111                 |
      | actual_cost     | num: 25.31                  |
      | co2_avoided     | num:11.1                   |
      | event_id        | DISP-2026-0901-01      |
      | currency        | EUR                    |
      | co2_mass_unit   | kg1                     |
    Then the expected status should be returned



