Feature: Check gaps and inactive status for settlements items

  Reference:  <JIRA_URL>/browse/ITAPPSIT-4155

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin
    Given this scenario is only supported for the preprd environment

  #
  # Happy path - active period only, no gaps expected
  #

  Scenario: Active reg hist period produces settlement_items with is_inactive false
    Given I want to do a scheduled settlement for product: GappyProgram type: ANCILLARY as of: "2027-02-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | bab05861-5d9c-4298-8f7b-8f0d68cb77ad |
      | mode        | FINAL                             |
      | start_date  | 2027-01-01                            |
      | end_date    | 2027-01-31                            |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "bab05861-5d9c-4298-8f7b-8f0d68cb77ad"
    And 5 settlement_item for product_id "bab05861-5d9c-4298-8f7b-8f0d68cb77ad" between "2027-01-01T00:00:00Z" and "2027-01-31T00:00:00Z" should have is_inactive false

  #
  # Gap caused by a non-ACTIVE status registration history row
  #

  Scenario: Non-ACTIVE reg hist status produces a settlement_item with is_inactive true
    Given I want to do a scheduled settlement for product: GappyProgram type: ANCILLARY as of: "2027-01-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | bab05861-5d9c-4298-8f7b-8f0d68cb77ad |
      | mode        | FINAL                             |
      | start_date  | 2026-12-01                            |
      | end_date    | 2026-12-31                            |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "bab05861-5d9c-4298-8f7b-8f0d68cb77ad"
    And 2 settlement_item for product_id "bab05861-5d9c-4298-8f7b-8f0d68cb77ad" between "2026-12-01T00:00:00Z" and "2027-01-01T00:00:00Z" should have is_inactive true
    When I calculate registration_history gaps for product_id "bab05861-5d9c-4298-8f7b-8f0d68cb77ad" registration_id "3a91c2e7-4b6d-4f18-9c2a-7e5d0f8b1a34" between "2026-12-01T00:00:00Z" and "2027-01-01T00:00:00Z"
    Then the registration_history gaps should be:
      | start_dttm_utc            | end_dttm_utc              |
      | 2026-12-10T00:00:00Z      | 2026-12-10T06:00:00Z      |
      | 2026-12-20T12:00:00Z      | 2026-12-21T00:00:00Z      |

  #
  # Reprocessing does not create duplicate items
  #

  Scenario: Re-run for already created gaps do not create new settlement_items.is_inactive true
    Given I want to do a scheduled settlement for product: RandomProgram type: ANCILLARY as of: "2026-12-11T00:00:00Z"
    When I POST a run-settlement-pipeline request with body
      | product_ids | bab05861-5d9c-4298-8f7b-8f0d68cb77ad |
      | mode        | FINAL                             |
      | start_date  | 2026-12-01                            |
      | end_date    | 2026-12-31                            |
    Then the run-settlement-pipeline response status should be 200
    And 2 settlement_item for product_id "bab05861-5d9c-4298-8f7b-8f0d68cb77ad" between "2026-12-01T00:00:00Z" and "2027-01-01T00:00:00Z" should have is_inactive true
    When I calculate registration_history gaps for product_id "bab05861-5d9c-4298-8f7b-8f0d68cb77ad" registration_id "3a91c2e7-4b6d-4f18-9c2a-7e5d0f8b1a34" between "2026-12-01T00:00:00Z" and "2027-01-01T00:00:00Z"
    Then the registration_history gaps should be:
      | start_dttm_utc            | end_dttm_utc              |
      | 2026-12-10T00:00:00Z      | 2026-12-10T06:00:00Z      |
      | 2026-12-20T12:00:00Z      | 2026-12-21T00:00:00Z      |


  #
  # Gaps caused by a non-ACTIVE status registration history row for another date
  #

  Scenario: Non-ACTIVE reg hist status produces a settlement_item with is_inactive true for other dates
    Given I want to do a scheduled settlement for product: GappyProgram type: ANCILLARY as of: "2027-02-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    Given I want to do a scheduled settlement for product: GappyProgram type: ANCILLARY as of: "2027-04-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database

    When I POST a run-settlement-pipeline request with body
      | product_ids | bab05861-5d9c-4298-8f7b-8f0d68cb77ad |
      | mode        | FINAL                             |
      | start_date  | 2027-03-01                            |
      | end_date    | 2027-03-31                            |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "bab05861-5d9c-4298-8f7b-8f0d68cb77ad"
    And 2 settlement_item for product_id "bab05861-5d9c-4298-8f7b-8f0d68cb77ad" between "2027-03-01T00:00:00Z" and "2027-04-01T00:00:00Z" should have is_inactive true
    When I calculate registration_history gaps for product_id "bab05861-5d9c-4298-8f7b-8f0d68cb77ad" registration_id "3a91c2e7-4b6d-4f18-9c2a-7e5d0f8b1a34" between "2027-03-01T00:00:00Z" and "2027-04-01T00:00:00Z"
    Then the registration_history gaps should be:
      | start_dttm_utc            | end_dttm_utc              |
      | 2027-03-05 00:00:00+00      | 2027-03-08 00:00:00+00      |
      | 2027-03-15 00:00:00+00      | 2027-03-18 00:00:00+00      |


  #
  # Gap caused by a non-ACTIVE (READY_TO_ENROLL) status registration history row
  #

  Scenario: READY_TO_ENROLL status for reg hist status produces a settlement_item with is_inactive true
    Given I want to do a scheduled settlement for product: GappyProgram type: ANCILLARY as of: "2027-01-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    Given I want to do a scheduled settlement for product: GappyProgram type: ANCILLARY as of: "2027-02-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | bab05861-5d9c-4298-8f7b-8f0d68cb77ad |
      | mode        | FINAL                             |
      | start_date  | 2027-01-01                            |
      | end_date    | 2027-01-31                            |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "bab05861-5d9c-4298-8f7b-8f0d68cb77ad"
    And 1 settlement_item for product_id "bab05861-5d9c-4298-8f7b-8f0d68cb77ad" between "2027-01-01T00:00:00Z" and "2027-02-01T00:00:00Z" should have is_inactive true



