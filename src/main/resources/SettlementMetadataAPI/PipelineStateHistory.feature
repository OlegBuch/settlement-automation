Feature: Testing the Pipeline State History API

  ITAPPSIT-3470:settlement metadata API: update to use pipeline state enums from Ref Data
  ITAPPSIT-3391: enhance settlement metadata API for settlement orchestrator: pipelinestate endpoints

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Basic case: create and then read a new pipeline history item for a settlement with no settlement-items

    #POST a new pipeline state history item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | status          | REQUESTED                |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    #GET the pipeline state history item
    When I read (GET) the same pipeline state history item
    Then the expected pipeline item should be returned in the response


  Scenario: Create and then read a new pipeline history item for a settlement with settlement-items

    #POST a new settlement-level pipeline state history item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | status          | REQUESTED                |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    #POST a new settlement_item-level pipeline state history item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <saved_state_settlement_id>   |
      | settlement_item_id | <uuid>                        |
      | pipeline_run_id    | <saved_state_pipeline_run_id> |
      | pipeline_step      | CREATOR_REST                  |
      | status             | REQUESTED                     |
      | detail             | QA check - ITAPPSIT-3391      |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    #GET the pipeline state history item by settlement_id
    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
    Then the number of returned items should be 2
    Then the expected pipeline item should be returned in the response

    #GET the pipeline state history item by pipeline_run_id
    When I GET the pipeline state history items with:
      | pipeline_run_id | <saved_state_pipeline_run_id> |
    Then the number of returned items should be 2
    Then the expected pipeline item should be returned in the response

    #GET the pipeline state history item by settlement_item_id
    When I GET the pipeline state history items with:
      | settlement_item_id | <saved_state_settlement_item_id> |
    Then the number of returned items should be 1
    Then the expected pipeline item should be returned in the response

    #POST a new pipeline state history item for the same setlement_id and a new settlement_item_id
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <saved_state_settlement_id>   |
      | settlement_item_id | <uuid>                        |
      | pipeline_run_id    | <saved_state_pipeline_run_id> |
      | pipeline_step      | CREATOR_REST                  |
      | status             | REQUESTED                     |
      | detail             | QA check - ITAPPSIT-3391      |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

   #GET the new pipeline state history item by settlement_id
    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
    Then the number of returned items should be 3
    And the expected pipeline item should be returned in the response

    #GET the new pipeline state history item by pipeline_run_id
    When I GET the pipeline state history items with:
      | pipeline_run_id | <saved_state_pipeline_run_id> |
    Then the number of returned items should be 3
    And the expected pipeline item should be returned in the response

    #GET the pipeline state history item by settlement_item_id
    When I GET the pipeline state history items with:
      | settlement_item_id | <saved_state_settlement_item_id> |
    Then the number of returned items should be 1
    And the expected pipeline item should be returned in the response

    #Save a time reference for later checks about the created_dttm_utc field
    Given I save a time reference

    #Go to the next status for the second pipeline state history item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <saved_state_settlement_id>   |
      | settlement_item_id | <saved_settlement_item_id>    |
      | pipeline_run_id    | <saved_state_pipeline_run_id> |
      | pipeline_step      | CREATOR_REST                  |
      | status             | STARTED                       |
      | detail             | QA check - ITAPPSIT-3391      |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    #GET the new pipeline state history item by settlement_id
    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
    Then the number of returned items should be 4
    And the expected pipeline item should be returned in the response

    #GET the new pipeline state history item by pipeline_run_id
    When I GET the pipeline state history items with:
      | pipeline_run_id | <saved_state_pipeline_run_id> |
    Then the number of returned items should be 4
    And the expected pipeline item should be returned in the response

    #GET the pipeline state history item by settlement_item_id
    When I GET the pipeline state history items with:
      | settlement_item_id | <saved_state_settlement_item_id> |
    Then the number of returned items should be 2
    And the expected pipeline item should be returned in the response

    #Go to the next step for the second pipeline state history item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <saved_state_settlement_id>   |
      | settlement_item_id | <saved_settlement_item_id>    |
      | pipeline_run_id    | <saved_state_pipeline_run_id> |
      | pipeline_step      | ECO                           |
      | status             | REQUESTED                     |
      | detail             | QA check - ITAPPSIT-3391      |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    
    #GET the new pipeline state history item by settlement_id
    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
    Then the number of returned items should be 5
    And the expected pipeline item should be returned in the response

    #GET the new pipeline state history item by settlement_id and pipeline_step
    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | pipeline_step | ECO                         |
    Then the number of returned items should be 1
    And the expected pipeline item should be returned in the response

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | pipeline_step | CREATOR_REST                |
    Then the number of returned items should be 4

    #GET the new pipeline state history item by pipeline_run_id and pipeline_step
    When I GET the pipeline state history items with:
      | pipeline_run_id | <saved_state_pipeline_run_id> |
      | pipeline_step   | ECO                           |
    Then the number of returned items should be 1
    And the expected pipeline item should be returned in the response

    When I GET the pipeline state history items with:
      | pipeline_run_id | <saved_state_pipeline_run_id> |
      | pipeline_step   | CREATOR_REST                  |
    Then the number of returned items should be 4

    #GET the new pipeline state history item by settlement_item_id and pipeline_step
    When I GET the pipeline state history items with:
      | settlement_item_id | <saved_state_settlement_item_id> |
      | pipeline_step      | ECO                              |
    Then the number of returned items should be 1
    And the expected pipeline item should be returned in the response

    When I GET the pipeline state history items with:
      | settlement_item_id | <saved_state_settlement_item_id> |
      | pipeline_step      | CREATOR_REST                     |
    Then the number of returned items should be 2

    #Filter by status
    When I GET the pipeline state history items with:
      | settlement_id     | <saved_state_settlement_id> |
      | excluded_statuses | STARTED                     |
    Then the number of returned items should be 4

    When I GET the pipeline state history items with:
      | settlement_id     | <saved_state_settlement_id> |
      | excluded_statuses | REQUESTED                   |
    Then the number of returned items should be 1

    #Filter by status and step
    When I GET the pipeline state history items with:
      | settlement_id     | <saved_state_settlement_id> |
      | excluded_statuses | REQUESTED                   |
      | pipeline_step     | ECO                         |
    Then the number of returned items should be 0

    When I GET the pipeline state history items with:
      | settlement_id     | <saved_state_settlement_id> |
      | excluded_statuses | STARTED                     |
      | pipeline_step     | ECO                         |
    Then the number of returned items should be 1
    And the expected pipeline item should be returned in the response

    #Filter by status, step and settlement_item_id
    When I GET the pipeline state history items with:
      | excluded_statuses  | STARTED                          |
      | pipeline_step      | CREATOR_REST                     |
      | settlement_item_id | <saved_state_settlement_item_id> |
    Then the number of returned items should be 1

    #Filter by settlement level
    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | level         | ALL                         |
    Then the number of returned items should be 5

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | level         | SETTLEMENT                  |
    Then the number of returned items should be 1

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | level         | ITEM                        |
    Then the number of returned items should be 4

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | level         | ITEM                        |
      | pipeline_step | ECO                         |
    Then the number of returned items should be 1
    And the expected pipeline item should be returned in the response

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | level         | SETTLEMENT                  |
      | pipeline_step | ECO                         |
    Then the number of returned items should be 0

    When I GET the pipeline state history items with:
      | pipeline_run_id | <saved_state_pipeline_run_id> |
      | level           | ITEM                          |
      | pipeline_step   | ECO                           |
    Then the number of returned items should be 1
    And the expected pipeline item should be returned in the response

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | per_page      | 2                           |
      | page          | 1                           |
    Then the number of returned items should be 2

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | per_page      | 2                           |
      | page          | 2                           |
    Then the number of returned items should be 2

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | per_page      | 2                           |
      | page          | 3                           |
    Then the number of returned items should be 1

    When I GET the pipeline state history items with:
      | settlement_id | <saved_state_settlement_id> |
      | per_page      | 2                           |
      | page          | 4                           |
    Then the number of returned items should be 0

    #Filter by created_dttm_utc
    When I GET the pipeline state history items with:
      | settlement_id           | <saved_state_settlement_id> |
      | created_dttm_before_utc | <saved_time_reference>      |
    Then the number of returned items should be 3

    #Clean up the pipeline state history table
#    Then I delete the pipeline state history items with:
#      | detail | <saved_state_detail> |


  Scenario: GET endpoint errors:

    # Malformed requests

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I call GET pipeline_state with an invalid query parameter settlement_id = foo
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I call GET pipeline_state with an invalid query parameter pipeline_run_id = foo
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I call GET pipeline_state with an invalid query parameter settlement_item_id = foo
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I call GET pipeline_state with an invalid query parameter created_dttm_before_utc = foo
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "Invalid pipeline_step: foo. Choose from: CREATOR_FIRST,CREATOR_REST,PERF_ENGINE,FIN_ENGINE,ECO,DONE"
    When I call GET pipeline_state with an invalid query parameter pipeline_step = foo
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "Invalid level: foo. Choose from: SETTLEMENT,ITEM,ALL"
    When I call GET pipeline_state with an invalid query parameter level = foo
    Then the expected status should be returned


  Scenario: POST endpoint errors

    # Malformed requests

    # missing settlement_id
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    Given I consider as expected a pipeline state history item with the following properties:
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | status          | REQUESTED                |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned

    # missing pipeline_run_id
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id | <uuid>                   |
      | pipeline_step | CREATOR_REST             |
      | status        | REQUESTED                |
      | detail        | QA check - ITAPPSIT-3391 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned

     # missing pipeline_step
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | status          | REQUESTED                |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned

    # missing status
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned

    # No parameters at all
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I create (POST) a faulty item with no properties
    Then the expected status should be returned

    # settlement_id is not a UUID
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | foo                      |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | status          | REQUESTED                |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned

    # settlement_item_id is not a UUID
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <uuid>                   |
      | settlement_item_id | foo                      |
      | pipeline_run_id    | <uuid>                   |
      | pipeline_step      | CREATOR_REST             |
      | status             | REQUESTED                |
      | detail             | QA check - ITAPPSIT-3391 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned

    # invalid step
    Given I expect the next API call to return a status code of 400 and details of "Invalid pipeline_step: foo. Choose from: CREATOR_FIRST,CREATOR_REST,PERF_ENGINE,FIN_ENGINE,ECO,DONE"
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | foo                      |
      | status          | REQUESTED                |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned

    # invalid status
    Given I expect the next API call to return a status code of 400 and details of "Invalid status: foo. Choose from: REQUESTED,STARTED,SUCCESS,FAILURE"
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | status          | foo                      |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned


  Scenario Outline: ITAPPSIT-3470 - POST endpoint accepts all the steps from ref service and GET endpoint accepts all levels from ref service

    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <uuid>                   |
      | settlement_item_id | <uuid>                   |
      | pipeline_run_id    | <uuid>                   |
      | pipeline_step      | <step>                   |
      | status             | REQUESTED                |
      | detail             | QA check - ITAPPSIT-3391 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    When I GET the pipeline state history items with:
      | settlement_item_id | <saved_state_settlement_item_id> |
      | level              | ALL                              |
    Then the number of returned items should be 1
    When  I GET the pipeline state history items with:
      | settlement_item_id | <saved_state_settlement_item_id> |
      | level              | SETTLEMENT                       |
    Then the number of returned items should be 1
    When  I GET the pipeline state history items with:
      | settlement_item_id | <saved_state_settlement_item_id> |
      | level              | ITEM                             |
    Then the number of returned items should be 1
    Examples:
      | step          |
      | CREATOR_FIRST |
      | CREATOR_REST  |
      | PERF_ENGINE   |
      | FIN_ENGINE    |
      | ECO           |
      | DONE          |


  Scenario Outline: ITAPPSIT-3470 - POST endpoint accepts all the statuses from ref service

    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | status          | <status>                 |
      | detail          | QA check - ITAPPSIT-3391 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    Examples:
      | status    |
      | REQUESTED |
      | STARTED   |
      | SUCCESS   |
      | FAILURE   |


  Scenario Outline: ITAPPSIT-3784 - Verify pipeline state history accepts and returns 'mode' field

    # POST a new item with mode explicitly set
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | status          | REQUESTED                |
      | mode            | <mode_val>               |
      | detail          | QA check - ITAPPSIT-3784 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # GET the item and verify mode is persisted
    When I read (GET) the same pipeline state history item
    Then the expected pipeline item should be returned in the response
    Examples:
      | mode_val  |
      | ESTIMATED |
      | FINAL     |


  Scenario: ITAPPSIT-3784 - Verify pipeline state history rejects invalid 'mode' field
    # POST a new item with invalid mode
    Given I expect the next API call to return a status code of 400 and details of "Invalid mode: foo. Choose from: FINAL, ESTIMATED"
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <uuid>                   |
      | pipeline_run_id | <uuid>                   |
      | pipeline_step   | CREATOR_REST             |
      | status          | REQUESTED                |
      | mode            | foo                      |
      | detail          | QA check - ITAPPSIT-3784 |
    When I create (POST) a faulty item with those properties
    Then the expected status should be returned
