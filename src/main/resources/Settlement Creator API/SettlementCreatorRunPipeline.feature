Feature: Run Settlement Creator Pipeline

  Reference: <JIRA_URL>/browse/ITAPPSIT-4054

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
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS
    Then the pipeline history should contain settlement item ids for the current pipeline_run_id

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
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS
    Then the pipeline history should contain settlement item ids for the current pipeline_run_id

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
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS
    Then the pipeline history should contain settlement item ids for the current pipeline_run_id

  Scenario: Happy path monthly estimated FCAS quarterly
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | FINAL                            |
      | start_date  | 2028-10-01                           |
      | end_date    | 2028-12-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    Then the pipeline history should contain 3 CREATOR_FIRST SUCCESS rows for the quarterly settlements


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
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "FINAL"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS
    Then the pipeline history should contain settlement item ids for the current pipeline_run_id


  Scenario: Happy path monthly FINAL AESO February
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2029-03-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2029-02-01                           |
      | end_date    | 2029-02-28                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "FINAL"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS
    Then the pipeline history should contain settlement item ids for the current pipeline_run_id


  Scenario: Happy path monthly FINAL AESO March
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2029-04-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2029-03-01                           |
      | end_date    | 2029-03-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "FINAL"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS
    Then the pipeline history should contain settlement item ids for the current pipeline_run_id

    Scenario: Happy path quarterly FINAL AESO
      When I POST a run-settlement-pipeline request with body
        | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
        | mode        | FINAL                                |
        | start_date  | 2029-01-01                           |
        | end_date    | 2029-03-31                           |
      Then the run-settlement-pipeline response status should be 200
      Then I save the pipeline_run_id from the response
      Then the pipeline history should contain 3 CREATOR_FIRST SUCCESS rows for the quarterly settlements

  #
  # Validation — Bad Request (400)
  #

  Scenario Outline: Validation scenarios
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a run-settlement-pipeline request with body
      | product_ids | <product_ids> |
      | mode        | <mode>        |
      | start_date  | <start_date>  |
      | end_date    | <end_date>    |
    Then the run-settlement-pipeline expected status should be returned

    Examples:
      | product_ids                                                              | mode     | start_date | end_date   |
      |                                                                          | FINAL    | 2026-01-01 | 2026-03-31 |
      | a1643547-425b-4856-8177-524371fa77e6                                     | FINAL111 | 2024-10-01 | 2024-10-31 |
      | a1643547-425b-4856-8177-524371fa77e6                                     |          | 2024-10-01 | 2024-10-31 |
      | a1643547-425b-4856-8177-524371fa77e6                                     | FINAL    |            | 2024-10-31 |
      | a1643547-425b-4856-8177-524371fa77e6                                     | FINAL    | 2024-10-01 |            |
      | a1643547-425b-4856-8177-524371fa77e6                                     | FINAL    | 2024-10-02 | 2024-10-31 |
      | a1643547-425b-4856-8177-524371fa77e6                                     | FINAL    | 2024-10-01 | 2024-10-10 |
      | a1643547-425b-4856-8177-524371fa77e6                                   | FINAL    | 2024-10-01 | 2024-11-30 |
      | a1643547-425b-4856-8177-524371fa77e6                                     | FINAL    | 2024-10-02 | 2024-12-31 |
      | a1643547-425b-4856-8177-524371fa77e6                                     | FINAL    | 2024-09-01 | 2024-10-31 |
      | 1ef635c7-65b2-4945-bdcb-aa2606956cfd                                     | FINAL    | 2026-14-01 | 2026-03-34 |
      | 1ef635c7-65b2-4945-bdcb-aa2606956cfd                                      | FINAL    | 2026-04-01 | 2026-03-30 |


  Scenario: Null product_ids entry
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a run-settlement-pipeline request with raw JSON body
    """
    {
      "product_ids": [null, "1ef635c7-65b2-4945-bdcb-aa2606956cfd"],
      "mode": "FINAL",
      "start_date": "2026-01-01",
      "end_date": "2026-03-31"
    }
    """
    Then the run-settlement-pipeline expected status should be returned

    #
# Security (401)
#

  Scenario: Missing x-api-key
    Given I do not include the API key header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | FINAL                                |
      | start_date  | 2026-01-01                           |
      | end_date    | 2026-03-31                           |
    Then the run-settlement-pipeline expected status should be returned

  Scenario: Invalid x-api-key
    Given I send an invalid API key
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | FINAL                                |
      | start_date  | 2026-01-01                           |
      | end_date    | 2026-03-31                           |
    Then the run-settlement-pipeline expected status should be returned

  Scenario: Missing enoc_session
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a run-settlement-pipeline request with body
      | product_ids | 1ef635c7-65b2-4945-bdcb-aa2606956cfd |
      | mode        | FINAL                                |
      | start_date  | 2026-01-01                           |
      | end_date    | 2026-03-31                           |
    Then the run-settlement-pipeline expected status should be returned