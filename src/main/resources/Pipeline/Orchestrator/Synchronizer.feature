Feature: Testing the synchronizer lambdas inside the orchestrator component

  ITAPPSIT-3538: settlement MVP test: verify no synchronizer race condition
  BDAP-2177: dlq subscription for orchestrator and synchronizer
  BDAP-2041: Settlement Synchronizer Part 2

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: A new settlement-item has been created successfully, its pipeline state is updated to CREATOR_REST - SUCCESS
      # expected result: we find CREATOR_REST - SUCCESS in the pipeline state history table for the settlement-item

  # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2041 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | SUCCESS                   |
      | step             | CREATOR_REST              |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status  |
      | <last-settlement-id> | CREATOR_REST | STARTED |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step         | status  |
      | <last-settlement-id> | <last-settlement-item-id> | CREATOR_REST | SUCCESS |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: After all settlement-items are created successfully, the settlement pipeline state is updated to CREATOR_REST - SUCCESS

      # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2041 event 1                     |
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
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | SUCCESS                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

 # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | SUCCESS                   |
      | step             | CREATOR_REST              |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status    |
      | <last-settlement-id> | CREATOR_REST | SUCCESS   |
      | <last-settlement-id> | ECO          | REQUESTED |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step         | status  |
      | <last-settlement-id> | <last-settlement-item-id> | CREATOR_REST | SUCCESS |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: ITAPPSIT-3785 - Synchronizer preserves ESTIMATED mode when aggregating item results

    # Create a settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | ITAPPSIT-3785 Sync Test               |
      | start_dttm_utc          | 2019-11-10T17:00:00Z                  |
      | end_dttm_utc            | 2019-11-11T08:00:00Z                  |
      | event_id                | <uuid>                                |
      | description             | QAA test: sync preserves estimated    |
      | settlement_status       | PRELIMINARY                           |
      | business_process_status | NOT_STARTED                           |
      | source_system_type      | NGP                                   |
      | product_id              | <product3>                            |
    Then the response should include the new settlement
    And the pipeline state for that settlement should have just been initialized

    # Initialize parent state
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>          |
      | pipeline_run_id | <uuid>                        |
      | pipeline_step   | CREATOR_REST                  |
      | status          | STARTED                       |
      | mode            | ESTIMATED                     |
      | detail          | QA check - ITAPPSIT-3785 Sync |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Item 1 Setup
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id>  |
      | settlement_level          | REGISTRATION          |
      | settlement_level_id       | ITAPPSIT-3785 level 1 |
      | submitted_indicator       | true                  |
      | settlement_item_status    | PRELIMINARY           |
      | asset_type                | LOAD                  |
      | processing_status         | CREATING              |
      | atlas_settlement_level_id | <uuid>                |
      | ecrm_opportunity_id       | abcdefghijklmnopqr    |
      | ecrm_account_id           | 123456789012345678    |
      | ecrm_site_id              | 098765432109876543    |
      | start_dttm_utc            | 2019-11-10T17:00:00Z  |
      | end_dttm_utc              | 2019-11-11T01:00:00Z  |
    Then the response should include the new settlement_item

    # Initialize Item 1 State
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>            |
      | settlement_item_id | <last-settlement-item-id>       |
      | pipeline_run_id    | <last-pipeline-run-id>          |
      | pipeline_step      | CREATOR_REST                    |
      | status             | STARTED                         |
      | mode               | ESTIMATED                       |
      | detail             | QA check - ITAPPSIT-3785 Item 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as settlement-item-id-1

    # Item 2 Setup
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id>  |
      | settlement_level          | REGISTRATION          |
      | settlement_level_id       | ITAPPSIT-3785 level 2 |
      | submitted_indicator       | true                  |
      | settlement_item_status    | PRELIMINARY           |
      | asset_type                | LOAD                  |
      | processing_status         | CREATING              |
      | atlas_settlement_level_id | <uuid>                |
      | ecrm_opportunity_id       | 123defghijklmnopqr    |
      | ecrm_account_id           | abc456789012345678    |
      | ecrm_site_id              | def765432109876543    |
      | start_dttm_utc            | 2019-11-11T01:00:00Z  |
      | end_dttm_utc              | 2019-11-11T08:00:00Z  |
    Then the response should include the new settlement_item

    # Initialize Item 2 State
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>      |
      | settlement_item_id | <last-settlement-item-id> |
      | pipeline_run_id    | <last-pipeline-run-id>    |
      | pipeline_step      | CREATOR_REST              |
      | status             | STARTED                   |
      | mode               | ESTIMATED                 |
      | detail             | QA check - Item 2         |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as settlement-item-id-2

    # Send Completion Messages
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>   |
      | settlementItemId | <settlement-item-id-1> |
      | action           | TASK_COMPLETED         |
      | caller           | CREATOR                |
      | pipelineRunId    | <last-pipeline-run-id> |
      | status           | SUCCESS                |
      | step             | CREATOR_REST           |
      | productId        | <product3>             |
      | mode             | ESTIMATED              |

    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>   |
      | settlementItemId | <settlement-item-id-2> |
      | action           | TASK_COMPLETED         |
      | caller           | CREATOR                |
      | pipelineRunId    | <last-pipeline-run-id> |
      | status           | SUCCESS                |
      | step             | CREATOR_REST           |
      | productId        | <product3>             |
      | mode             | ESTIMATED              |
    And I wait 5 seconds

    # Assert
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status  | mode      |
      | <last-settlement-id> | CREATOR_REST | SUCCESS | ESTIMATED |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step          | status  | mode      |
      | <last-settlement-id> | <last-settlement-item-id> | CREATOR_REST  | SUCCESS | ESTIMATED |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: ITAPPSIT-3785 - Synchronizer preserves FINAL mode when aggregating item results

    # Create a settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | ITAPPSIT-3785 Sync Final                  |
      | start_dttm_utc          | 2019-11-10T17:00:00Z                  |
      | end_dttm_utc            | 2019-11-11T08:00:00Z                  |
      | event_id                | <uuid>                                |
      | description             | QAA test: sync preserves FINAL        |
      | settlement_status       | PRELIMINARY                           |
      | business_process_status | NOT_STARTED                           |
      | source_system_type      | NGP                                   |
      | product_id              | <product3>                            |
    Then the response should include the new settlement

    # Initialize parent state
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | STARTED                      |
      | mode            | FINAL                        |
      | detail          | QA check - ITAPPSIT-3785 Sync    |
    When I create (POST) that item

    # Item 1 Setup
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item

    # Initialize Item 1 State
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>      |
      | settlement_item_id | <last-settlement-item-id> |
      | pipeline_run_id    | <last-pipeline-run-id>    |
      | pipeline_step      | CREATOR_REST              |
      | status             | STARTED                   |
      | mode               | FINAL                     |
      | detail             | QA check - Item 1         |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as settlement-item-id-1

    # Item 2 Setup
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item

    # Initialize Item 2 State
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>      |
      | settlement_item_id | <last-settlement-item-id> |
      | pipeline_run_id    | <last-pipeline-run-id>    |
      | pipeline_step      | CREATOR_REST              |
      | status             | STARTED                   |
      | mode               | FINAL                     |
      | detail             | QA check - Item 2         |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as settlement-item-id-2

    # Send Completion Messages with FINAL
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>   |
      | settlementItemId | <settlement-item-id-1> |
      | action           | TASK_COMPLETED         |
      | caller           | CREATOR                |
      | pipelineRunId    | <last-pipeline-run-id> |
      | status           | SUCCESS                |
      | step             | CREATOR_REST           |
      | productId        | <product3>             |
      | mode             | FINAL                  |

    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>   |
      | settlementItemId | <settlement-item-id-2> |
      | action           | TASK_COMPLETED         |
      | caller           | CREATOR                |
      | pipelineRunId    | <last-pipeline-run-id> |
      | status           | SUCCESS                |
      | step             | CREATOR_REST           |
      | productId        | <product3>             |
      | mode             | FINAL                  |
    And I wait 5 seconds

    # Assert
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status  | mode  |
      | <last-settlement-id> | CREATOR_REST | SUCCESS | FINAL |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: All settlement-items except one are created successfully, the settlement pipeline state is updated to CREATOR_REST - SUCCESS

      # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2041 event 1                     |
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
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | SUCCESS                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

 # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | FAILURE                   |
      | step             | CREATOR_REST              |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status  |
      | <last-settlement-id> | CREATOR_REST | SUCCESS |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step         | status  |
      | <last-settlement-id> | <last-settlement-item-id> | CREATOR_REST | FAILURE |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: ITAPPSIT-3538 : all settlement-items are created successfully, a single pipeline state history item for the settlement is posted with CREATOR_REST - SUCCESS

  NOTE: Make sure a race condition can reliably be triggered by inserting some sleep time before the status update in the synchronizer code

      # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2041 event 1                     |
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
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as settlement-item-id-1

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as settlement-item-id-2

    # Update the first item
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>   |
      | settlementItemId | <settlement-item-id-1> |
      | action           | TASK_COMPLETED         |
      | caller           | CREATOR                |
      | pipelineRunId    | <last-pipeline-run-id> |
      | status           | SUCCESS                |
      | step             | CREATOR_REST           |
      | productId        | <product3>             |

  # Update the second item
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>   |
      | settlementItemId | <settlement-item-id-2> |
      | action           | TASK_COMPLETED         |
      | caller           | CREATOR                |
      | pipelineRunId    | <last-pipeline-run-id> |
      | status           | SUCCESS                |
      | step             | CREATOR_REST           |
      | productId        | <product3>             |
      | delay            | 10                     |
    And I wait 60 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find a single pipeline state history item:
      | settlement-id        | step         | status  |
      | <last-settlement-id> | CREATOR_REST | SUCCESS |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


#  Scenario: NEW_ERROR_CASE: a settlement-item is created after the settlement status is updated to CREATOR_REST - SUCCESS
#
#  NOTE: Make sure a race condition can reliably be triggered by inserting some sleep time before the status update in the synchronizer code
#
#      # POST a new settlement
#    When I POST a settlement with the following properties:
#      | settlement_type         | ANCILLARY                             |
#      | settlement_subtype      | BDAP-2041 event 1                     |
#      | start_dttm_utc          | 2019-11-10T17:00:00Z                  |
#      | end_dttm_utc            | 2019-11-11T08:00:00Z                  |
#      | event_id                | <uuid>                                |
#      | description             | QAA test: orchestrator business logic |
#      | settlement_status       | PRELIMINARY                           |
#      | business_process_status | NOT_STARTED                           |
#      | source_system_type      | NGP                                   |
#      | product_id              | <product3>                            |
#    Then the response should include the new settlement
#    And the pipeline state for that settlement should have just been initialized
#    Given I consider as expected a pipeline state history item with the following properties:
#      | settlement_id   | <last-settlement-id>         |
#      | pipeline_run_id | <uuid>                       |
#      | pipeline_step   | CREATOR_REST                 |
#      | status          | STARTED                      |
#      | detail          | QA check - BDAP-2041 event 1 |
#    When I create (POST) that item
#    Then the expected pipeline item should be returned in the response
#
#    When I POST a settlement_item with the following properties:
#      | settlement_id             | <last-settlement-id> |
#      | settlement_level          | REGISTRATION         |
#      | settlement_level_id       | <uuid>               |
#      | submitted_indicator       | true                 |
#      | settlement_item_status    | PRELIMINARY          |
#      | asset_type                | LOAD                 |
#      | processing_status         | CREATING             |
#      | atlas_settlement_level_id | <uuid>               |
#      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
#      | ecrm_account_id           | 123456789012345678   |
#      | ecrm_site_id              | 098765432109876543   |
#      | start_dttm_utc            | 2019-11-10T17:00:00Z |
#      | end_dttm_utc              | 2019-11-11T01:00:00Z |
#    Then the response should include the new settlement_item
#    Given I consider as expected a pipeline state history item with the following properties:
#      | settlement_id      | <last-settlement-id>         |
#      | settlement_item_id | <last-settlement-item-id>    |
#      | pipeline_run_id    | <last-pipeline-run-id>       |
#      | pipeline_step      | CREATOR_REST                 |
#      | status             | STARTED                      |
#      | detail             | QA check - BDAP-2041 event 1 |
#    When I create (POST) that item
#    Then the expected pipeline item should be returned in the response
#
#    # Update the first item
#    When I send a message to the SQS Intervals Output Queue using the following parameters:
#      | settlementId     | <last-settlement-id>      |
#      | settlementItemId | <last-settlement-item-id> |
#      | action           | TASK_COMPLETED            |
#      | caller           | CREATOR                   |
#      | pipelineRunId    | <last-pipeline-run-id>    |
#      | status           | SUCCESS                   |
#      | step             | CREATOR_REST              |
#      | productId        | <product3>                |
#    And I wait 5 seconds
#
#    And I GET all the pipeline states for that pipeline run
#    Then for each of the following settlements I should find a single pipeline state history item:
#      | settlement-id        | step         | status  |
#      | <last-settlement-id> | CREATOR_REST | SUCCESS |
#
# # Second settlement item
#    When I POST a settlement_item with the following properties:
#      | settlement_id             | <last-settlement-id> |
#      | settlement_level          | REGISTRATION         |
#      | settlement_level_id       | BDAP-2041 level 2    |
#      | submitted_indicator       | true                 |
#      | settlement_item_status    | AWAITING_DATA        |
#      | asset_type                | DER_BESS             |
#      | processing_status         | IN_PROCESS           |
#      | atlas_settlement_level_id | <uuid>               |
#      | ecrm_opportunity_id       | 123defghijklmnopqr   |
#      | ecrm_account_id           | abc456789012345678   |
#      | ecrm_site_id              | def765432109876543   |
#      | start_dttm_utc            | 2019-11-11T01:00:00Z |
#      | end_dttm_utc              | 2019-11-11T08:00:00Z |
#    Then the response should include the new settlement_item
#    # POST new pipeline state history items for the settlement item
#    Given I consider as expected for the new entity a pipeline state history item with the following properties:
#      | settlement_id      | <last-settlement-id>         |
#      | settlement_item_id | <last-settlement-item-id>    |
#      | pipeline_run_id    | <last-pipeline-run-id>       |
#      | pipeline_step      | CREATOR_REST                 |
#      | status             | STARTED                      |
#      | detail             | QA check - BDAP-2041 event 1 |
#    When I create (POST) that item
#    Then the expected pipeline item should be returned in the response
#
#  # Update the second item
#    When I send a message to the SQS Intervals Output Queue using the following parameters:
#      | settlementId     | <last-settlement-id>      |
#      | settlementItemId | <last-settlement-item-id> |
#      | action           | TASK_COMPLETED            |
#      | caller           | CREATOR                   |
#      | pipelineRunId    | <last-pipeline-run-id>    |
#      | status           | SUCCESS                   |
#      | step             | CREATOR_REST              |
#      | productId        | <product3>                |
#    And I wait 5 seconds
#
#    # Verify the pipeline run has been completed as expected
#    And I GET all the pipeline states for that pipeline run
#    Then for each of the following settlements I should find a single pipeline state history item:
#      | settlement-id        | step         | status  |
#      | <last-settlement-id> | CREATOR_REST | SUCCESS |
#
#  # Clean up
#    When I DELETE the settlement
#    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: Payment calculations have completed for a given settlement-item, its pipeline state is updated to ECO - SUCCESS

  # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2041 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | ECO                          |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS ECO Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | ECO                       |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | SUCCESS                   |
      | step             | ECO                       |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step | status  |
      | <last-settlement-id> | <last-settlement-item-id> | ECO  | SUCCESS |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: Payment calculations have successfully completed for all settlement-item, the pipeline state for the parent settlement is updated to ECO - SUCCESS

  # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2041 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | ECO                          |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | SUCCESS                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS ECO Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | ECO                       |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | SUCCESS                   |
      | step             | ECO                       |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step | status  |
      | <last-settlement-id> | ECO  | SUCCESS |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step | status  |
      | <last-settlement-id> | <last-settlement-item-id> | ECO  | SUCCESS |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: Payment calculations have successfully completed for all settlement-item except one, the pipeline state for the parent settlement is updated to ECO - SUCCESS

  # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2041 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | ECO                          |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | SUCCESS                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS ECO Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | ECO                       |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | FAILURE                   |
      | step             | ECO                       |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step | status  |
      | <last-settlement-id> | ECO  | SUCCESS |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step | status  |
      | <last-settlement-id> | <last-settlement-item-id> | ECO  | FAILURE |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: ITAPPSIT-3538 - payment calculations have successfully completed for all settlement-item, a single pipeline history item with ECO - SUCCESS is posted for the parent settlement

  # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2041 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | ECO                          |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | <uuid>               |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as settlement-item-id-1

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2041 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as settlement-item-id-2

    # Update first item
    When I send a message to the SQS ECO Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>   |
      | settlementItemId | <settlement-item-id-1> |
      | action           | TASK_COMPLETED         |
      | caller           | ECO                    |
      | pipelineRunId    | <last-pipeline-run-id> |
      | status           | SUCCESS                |
      | step             | ECO                    |
      | productId        | <product3>             |

  # Update the second item
    When I send a message to the SQS ECO Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>   |
      | settlementItemId | <settlement-item-id-2> |
      | action           | TASK_COMPLETED         |
      | caller           | ECO                    |
      | pipelineRunId    | <last-pipeline-run-id> |
      | status           | SUCCESS                |
      | step             | ECO                    |
      | productId        | <product3>             |
      | delay            | 10                     |
    And I wait 60 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find a single pipeline state history item:
      | settlement-id        | step | status  |
      | <last-settlement-id> | ECO  | SUCCESS |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: BDAP-2177 - The creation of a settlement-item was unsuccessful, its pipeline state is updated to CREATOR_REST - FAILURE

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2177 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T05:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as dlq-settlement-item-id

  # Send a message to the orchestrator
    When I send a message to the SQS Intervals Input Dead Letter Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | STARTED                   |
      | step             | CREATOR_REST              |
      | productId        | <product3>                |
#    And I wait 5 seconds

    # Third settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 3    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T05:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Send a message to the orchestrator
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | SUCCESS                   |
      | step             | CREATOR_REST              |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status  |
      | <last-settlement-id> | CREATOR_REST | STARTED |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id       | step         | status  |
      | <last-settlement-id> | <dlq-settlement-item-id> | CREATOR_REST | FAILURE |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 3 settlement items and 0 settlement item intervals


  Scenario: BDAP-2177 - The creation of the last settlement-item was unsuccessful, its pipeline state is updated to CREATOR_REST - FAILURE

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2177 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS Intervals Input Dead Letter Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | STARTED                   |
      | step             | CREATOR_REST              |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status  |
      | <last-settlement-id> | CREATOR_REST | STARTED |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step         | status  |
      | <last-settlement-id> | <last-settlement-item-id> | CREATOR_REST | FAILURE |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: BDAP-2177 - The creation of all items for a given settlement was successful, except for the last one, the pipeline state for the parent settlement is updated to CREATOR_REST - SUCCESS

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2177 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | CREATOR_REST                 |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | SUCCESS                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | CREATOR_REST                 |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS Intervals Input Dead Letter Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | STARTED                   |
      | step             | CREATOR_REST              |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step         | status  |
      | <last-settlement-id> | CREATOR_REST | SUCCESS |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step         | status  |
      | <last-settlement-id> | <last-settlement-item-id> | CREATOR_REST | FAILURE |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: BDAP-2177 - Payment calculations was unsuccessful for the last settlement-item, its pipeline state is updated to ECO - FAILURE

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2177 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | ECO                          |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS ECO Input Dead Letter Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | STARTED                   |
      | step             | ECO                       |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step | status  |
      | <last-settlement-id> | ECO  | STARTED |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step | status  |
      | <last-settlement-id> | <last-settlement-item-id> | ECO  | FAILURE |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: BDAP-2177 - Payment calculations for a settlement-item was unsuccessful, its pipeline state is updated to ECO - FAILURE

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2177 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | ECO                          |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T05:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response
    And I save the settlement item id as dlq-settlement-item-id

  # Send a message to the orchestrator
    When I send a message to the SQS Intervals Input Dead Letter Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | STARTED                   |
      | step             | ECO                       |
      | productId        | <product3>                |
#    And I wait 5 seconds

    # Third settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 3    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T05:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Send a message to the orchestrator
    When I send a message to the SQS Intervals Output Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | SUCCESS                   |
      | step             | ECO                       |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step | status  |
      | <last-settlement-id> | ECO  | STARTED |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id       | step | status  |
      | <last-settlement-id> | <dlq-settlement-item-id> | ECO  | FAILURE |

  # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 3 settlement items and 0 settlement item intervals


  Scenario: BDAP-2177 - Payment calculations have successfully completed for all settlement-item except for the last one, the pipeline state for the parent settlement is updated to ECO - SUCCESS

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                             |
      | settlement_subtype      | BDAP-2177 event 1                     |
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
    #POST pipeline state history items for the settlement
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id   | <last-settlement-id>         |
      | pipeline_run_id | <uuid>                       |
      | pipeline_step   | ECO                          |
      | status          | STARTED                      |
      | detail          | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # First settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | PRELIMINARY          |
      | asset_type                | LOAD                 |
      | processing_status         | CREATING             |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | abcdefghijklmnopqr   |
      | ecrm_account_id           | 123456789012345678   |
      | ecrm_site_id              | 098765432109876543   |
      | start_dttm_utc            | 2019-11-10T17:00:00Z |
      | end_dttm_utc              | 2019-11-11T01:00:00Z |
    Then the response should include the new settlement_item
    # POST pipeline state history items for the settlement item
    Given I consider as expected a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | SUCCESS                      |
      | detail             | QA check - BDAP-2041 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

    # Second settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | BDAP-2177 level 2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_BESS             |
      | processing_status         | IN_PROCESS           |
      | atlas_settlement_level_id | <uuid>               |
      | ecrm_opportunity_id       | 123defghijklmnopqr   |
      | ecrm_account_id           | abc456789012345678   |
      | ecrm_site_id              | def765432109876543   |
      | start_dttm_utc            | 2019-11-11T01:00:00Z |
      | end_dttm_utc              | 2019-11-11T08:00:00Z |
    Then the response should include the new settlement_item
    # POST new pipeline state history items for the settlement item
    Given I consider as expected for the new entity a pipeline state history item with the following properties:
      | settlement_id      | <last-settlement-id>         |
      | settlement_item_id | <last-settlement-item-id>    |
      | pipeline_run_id    | <last-pipeline-run-id>       |
      | pipeline_step      | ECO                          |
      | status             | STARTED                      |
      | detail             | QA check - BDAP-2177 event 1 |
    When I create (POST) that item
    Then the expected pipeline item should be returned in the response

  # Send a message to the orchestrator
    When I send a message to the SQS ECO Input Dead Letter Queue using the following parameters:
      | settlementId     | <last-settlement-id>      |
      | settlementItemId | <last-settlement-item-id> |
      | action           | TASK_COMPLETED            |
      | caller           | CREATOR                   |
      | pipelineRunId    | <last-pipeline-run-id>    |
      | status           | STARTED                   |
      | step             | ECO                       |
      | productId        | <product3>                |
    And I wait 5 seconds

    # Verify the pipeline run has been completed as expected
    And I GET all the pipeline states for that pipeline run
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step | status  |
      | <last-settlement-id> | ECO  | SUCCESS |
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | settlement-item-id        | step | status  |
      | <last-settlement-id> | <last-settlement-item-id> | ECO  | FAILURE |

    # Clean up
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals