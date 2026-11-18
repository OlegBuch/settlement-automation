Feature: Testing the orchestrator business logic

  BDAP-1841: settlement orchestrator business logic

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: orchestrator processes a newly created settlement
      # expected result: we find CREATOR_REST - REQUESTED and CREATOR_REST - STARTED items in the pipeline state history table

    # We need to post a fresh settlement to be processed. Verify that no settlement exists with the chosen parameters
    Given I verify that no settlement exists with the event "BDAP-1841 event 1"

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-1841 event 1                     |
      | start_dttm_utc          | 2019-11-10T17:00:00Z                  |
      | end_dttm_utc            | 2019-11-11T08:00:00Z                  |
      | event_id                | <uuid>                                |
      | description             | QAA test: orchestrator business logic |
      | settlement_status       | PRELIMINARY                           |
      | business_process_status | NOT_STARTED                           |
      | source_system_type      | NGP                                   |
      | product_id              | <product3>                            |
    Then the response should include the new settlement
    And the pipeline state for that settlement should have just been initialized

    #POST a new pipeline state history item for the first step
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_FIRST                |
      | status          | SUCCESS                      |
      | detail          | QA check - BDAP-1841 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Send a message to the orchestrator to start the pipeline run
    When I send a message to the SQS Orchestrator Input Queue using the following parameters:
      | settlementId  | <last-settlement-id>   |
      | action        | RUN_PIPELINE           |
      | caller        | CREATOR                |
      | pipelineRunId | <last-pipeline-run-id> |
      | status        | SUCCESS                |
      | step          | CREATOR_FIRST          |
      | productId     | <product3>             |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    # NOTE: We will find the CREATOR_REST - STARTED item only if the Creator is enabled. This is proof the Orchestrator sent the right message on the right queue
    # If that item is not found check SpPlunk or the AWS console to see if the Creator is disabled
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step          | status    |
      | <last-settlement-id> | CREATOR_FIRST | SUCCESS   |
      | <last-settlement-id> | CREATOR_REST  | REQUESTED |
      | <last-settlement-id> | CREATOR_REST  | STARTED   |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status


  Scenario: orchestrator engages ECO for a settlement
      # expected result: we find ECO - REQUESTED and ECO - STARTED items in the pipeline state history table for the settlement

  # We need to post a fresh settlement to be processed. Verify that no settlement exists with the chosen parameters
    Given I verify that no settlement exists with the event "BDAP-1841 event 2"

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-1841 event 2                     |
      | start_dttm_utc          | 2019-11-10T17:00:00Z                  |
      | end_dttm_utc            | 2019-11-11T08:00:00Z                  |
      | event_id                | <uuid>                                |
      | description             | QAA test: orchestrator business logic |
      | settlement_status       | PRELIMINARY                           |
      | business_process_status | NOT_STARTED                           |
      | source_system_type      | NGP                                   |
      | product_id              | <product3>                            |
    Then the response should include the new settlement
    And the pipeline state for that settlement should have just been initialized

    #POST a new pipeline state history item for the first step
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | SUCCESS                      |
      | detail          | QA check - BDAP-1841 event 2 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Send a message to the orchestrator to start the pipeline run
    When I send a message to the SQS Orchestrator Input Queue using the following parameters:
      | settlementId  | <last-settlement-id>   |
      | action        | RUN_PIPELINE           |
      | caller        | CREATOR                |
      | pipelineRunId | <last-pipeline-run-id> |
      | status        | SUCCESS                |
      | step          | CREATOR_REST           |
      | productId     | <product3>             |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    # NOTE: We will find the ECO - STARTED item only if ECO is enabled. This is proof the Orchestrator sent the right message on the right queue
    # If that item is not found check Splunk or the AWS console to see if the ECO is disabled
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status    |
      | <last-settlement-id> | CREATOR_REST | SUCCESS   |
      | <last-settlement-id> | ECO          | REQUESTED |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status


  Scenario: the pipeline processing run is completed
      # expected result: we find the DONE - SUCCESS  item in the pipeline state history table for the settlement

  # We need to post a fresh settlement to be processed. Verify that no settlement exists with the chosen parameters
    Given I verify that no settlement exists with the event "BDAP-1841 event 3"

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-1841 event 3                     |
      | start_dttm_utc          | 2019-11-10T17:00:00Z                  |
      | end_dttm_utc            | 2019-11-11T08:00:00Z                  |
      | event_id                | <uuid>                                |
      | description             | QAA test: orchestrator business logic |
      | settlement_status       | PRELIMINARY                           |
      | business_process_status | NOT_STARTED                           |
      | source_system_type      | NGP                                   |
      | product_id              | <product3>                            |
    Then the response should include the new settlement
    And the pipeline state for that settlement should have just been initialized

    #POST a new pipeline state history item for the first step
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | ECO                          |
      | status          | SUCCESS                      |
      | detail          | QA check - BDAP-1841 event 3 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Send a message to the orchestrator to start the pipeline run
    When I send a message to the SQS Orchestrator Input Queue using the following parameters:
      | settlementId  | <last-settlement-id>   |
      | action        | RUN_PIPELINE           |
      | caller        | ECO                    |
      | pipelineRunId | <last-pipeline-run-id> |
      | status        | SUCCESS                |
      | step          | ECO                    |
      | productId     | <product3>             |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    # NOTE: We will find the ECO - STARTED item only if ECO is enabled. This is proof the Orchestrator sent the right message on the right queue
    # If that item is not found check Splunk or the AWS console to see if the ECO is disabled
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step | status  |
      | <last-settlement-id> | DONE | SUCCESS |
      | <last-settlement-id> | ECO  | SUCCESS |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status


  Scenario: ITAPPSIT-3785 - Orchestrator preserves ESTIMATED mode
    # Create a settlement to process
    Given I verify that no settlement exists with the event "ITAPPSIT-3785 test"

    # Include ALL required fields here
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                                  |
      | settlement_subtype      | ITAPPSIT-3785 test                         |
      | start_dttm_utc          | 2019-11-10T17:00:00Z                       |
      | end_dttm_utc            | 2019-11-11T08:00:00Z                       |
      | event_id                | <uuid>                                     |
      | description             | QAA test: orchestrator preserves ESTIMATED |
      | settlement_status       | PRELIMINARY                                |
      | business_process_status | NOT_STARTED                                |
      | source_system_type      | NGP                                        |
      | product_id              | <product3>                                 |
    Then the response should include the new settlement
    And the pipeline state for that settlement should have just been initialized

    #POST a new pipeline state history item for the first step
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>             |
      | pipeline_run_id | <uuid>                           |
      | pipeline_step   | CREATOR_FIRST                    |
      | status          | SUCCESS                          |
      | mode            | ESTIMATED                        |
      | detail          | QA check - ITAPPSIT-3785 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Inject a message mimicking the Creator sending an ESTIMATED run
    When I send a message to the SQS Orchestrator Input Queue using the following parameters:
      | settlementId  | <last-settlement-id>   |
      | action        | RUN_PIPELINE           |
      | caller        | CREATOR                |
      | pipelineRunId | <last-pipeline-run-id> |
      | status        | SUCCESS                |
      | step          | CREATOR_FIRST          |
      | productId     | <product3>             |
      | mode          | ESTIMATED              |
    And I wait 5 seconds

    # Verify Orchestrator wrote "ESTIMATED" to the history table
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step          | status    | mode      |
      | <last-settlement-id> | CREATOR_FIRST | SUCCESS   | ESTIMATED |
      | <last-settlement-id> | CREATOR_REST  | REQUESTED | ESTIMATED |
      | <last-settlement-id> | CREATOR_REST  | STARTED   | ESTIMATED |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status


  Scenario: ITAPPSIT-3785 - Orchestrator defaults to FINAL mode when parameter is missing
    # Create a settlement
    Given I verify that no settlement exists with the event "ITAPPSIT-3785 default test"
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | ITAPPSIT-3785 default test            |
      | start_dttm_utc          | 2019-11-10T17:00:00Z                  |
      | end_dttm_utc            | 2019-11-11T08:00:00Z                  |
      | event_id                | <uuid>                                |
      | description             | QAA test: orchestrator defaults FINAL |
      | settlement_status       | PRELIMINARY                           |
      | business_process_status | NOT_STARTED                           |
      | source_system_type      | NGP                                   |
      | product_id              | <product3>                            |
    Then the response should include the new settlement
    And the pipeline state for that settlement should have just been initialized

    # Create the prerequisite history item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>             |
      | pipeline_run_id | <uuid>                           |
      | pipeline_step   | CREATOR_FIRST                    |
      | status          | SUCCESS                          |
      | mode            | FINAL                            |
      | detail          | QA check - ITAPPSIT-3785 default |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Send a message WITHOUT the 'mode' parameter
    # The system should interpret missing mode as "FINAL"
    When I send a message to the SQS Orchestrator Input Queue using the following parameters:
      | settlementId  | <last-settlement-id>   |
      | action        | RUN_PIPELINE           |
      | caller        | CREATOR                |
      | pipelineRunId | <last-pipeline-run-id> |
      | status        | SUCCESS                |
      | step          | CREATOR_FIRST          |
      | productId     | <product3>             |
    And I wait 5 seconds

    # Verify Orchestrator wrote "FINAL" to the history table
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step          | status    | mode  |
      | <last-settlement-id> | CREATOR_FIRST | SUCCESS   | FINAL |
      | <last-settlement-id> | CREATOR_REST  | REQUESTED | FINAL |
      | <last-settlement-id> | CREATOR_REST  | STARTED   | FINAL |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status


#  Scenario: End-to-end test: a settlement is processed through the settlement pipeline
#      #NB: this scenario is a placeholder for a more comprehensive end-to-end test where all of the necessary setup has been done on the several systems engaged
