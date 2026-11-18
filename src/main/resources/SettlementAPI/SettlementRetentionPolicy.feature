Feature: Retention Policy for settlements

  Reference: <JIRA_URL>/browse/ITAPPSIT-4079

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin
    Given this scenario is only supported for the preprd environment

  #
  # Happy paths
  #

  Scenario: Happy path monthly estimated FCAS October
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2028-11-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | ESTIMATED                            |
      | start_date  | 2028-10-01                           |
      | end_date    | 2028-10-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And all created settlements for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd" and product FCAS should have inputs_available_until_dttm_utc populated

  # Before we run this scenario
  # Set up for this created settlement_id from settlements table
  # inputs_available_until_dttm_utc column - value in the past
  # then run this scenario
  # then we see in splunk by quering index="stm_preprd" 9c60aa90-c108-4e3e-9c6a-de58262ab06e (pipeline_run_id) AND "inputs_available_until_dttm_utc is in the past;"
  # error message
  # message: inputs_available_until_dttm_utc is in the past; will not attempt to fetch intervals from source systems
  Scenario: Error path monthly estimated FCAS October
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | ESTIMATED                            |
      | start_date  | 2028-10-01                           |
      | end_date    | 2028-10-31                           |
    Then the run-settlement-pipeline response status should be 200


  Scenario: Happy path monthly estimated FCAS November
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2028-12-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | ESTIMATED                            |
      | start_date  | 2028-11-01                           |
      | end_date    | 2028-11-30                           |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And all created settlements for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd" and product FCAS should have inputs_available_until_dttm_utc populated

  Scenario: Happy path monthly estimated FCAS December
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2029-01-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | ESTIMATED                            |
      | start_date  | 2028-12-01                           |
      | end_date    | 2028-12-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And all created settlements for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd" and product FCAS should have inputs_available_until_dttm_utc populated

  Scenario: Happy path monthly estimated FCAS quarterly
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | FINAL                            |
      | start_date  | 2028-10-01                           |
      | end_date    | 2028-12-31                           |
    Then the run-settlement-pipeline response status should be 200
    And all settlements for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd" between "2028-10-01" and "2028-12-31" should still have inputs_available_until_dttm_utc populated

  Scenario: Happy path monthly FINAL AESO January
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2029-02-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2029-01-01                           |
      | end_date    | 2029-01-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "a1643547-425b-4856-8177-524371fa77e6"
    And all created settlements for product_id "a1643547-425b-4856-8177-524371fa77e6" and product AESO should have inputs_available_until_dttm_utc populated

 # not populated neither AESO OR nor FCAS product
  Scenario: inputs_available_until_dttm_utc null - no AESO OR or FCAS product associated
    Given I want to do a scheduled settlement for product: RandomProgram type: ANCILLARY as of: "2029-02-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | 48a52ada-f785-4505-9c28-917f82f04ff9 |
      | mode        | ESTIMATED                                |
      | start_date  | 2029-01-01                           |
      | end_date    | 2029-01-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I query and log settlements for product "48a52ada-f785-4505-9c28-917f82f04ff9"
    When all created settlements for product "48a52ada-f785-4505-9c28-917f82f04ff9" should have inputs_available_until_dttm_utc as null

