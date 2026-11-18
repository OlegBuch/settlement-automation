Feature: Performance tests for interval sets


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin
    Given I set the SQL INSERT intervals batch size to 200


  Scenario: Basic scenario

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for interval performance |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals_summary
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the expected status should be returned

    # Batch contains an interval with a different settlement_item_id. Entire POST should fail.
    Given I want to include an interval with a random settlement item id
    Given I expect the next API call to return a status code of 400 and details of "all settlement_item_id must be the same"
    Given I POST a set of 5 intervals for settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Batch contains an interval with a bad enumeration. Entire POST should fail.
    Given I want to include an interval with a bad enumeration
    Given I expect the next API call to return a status code of 400 and details of "Invalid interval_source"
    Given I POST a set of 5 intervals for settlement_item_id Item1
    Then the expected status should be returned

    Given I reset the intervals start date and flags
    Given I POST a set of batchSizeMinusOne intervals for settlement_item_id Item1
    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I POST a set of batchSize intervals starting with interval 210 for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I POST a set of batchSizePlusOne intervals starting with interval 500 for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # DELETE
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify the expected number of settlement item intervals
    And changes should be recorded in the settlement_item audit log

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals_summary
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the expected status should be returned

    # Cleanup
    Given I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals


  Scenario: Second batch contains a duplicate timestamp

    In this case, the entire transaction should be rolled back and no intervals stored.

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for interval performance |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given I POST a set of batchSize intervals for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I want to log all API responses

    # Second batch contains a duplicate timestamp. Entire POST should fail.
    Given I want to include a duplicate interval from the first batch
    Given I expect the next API call to return a status code of 400 and details of "all interval_dttm_utc must be unique"
    Given I POST a set of batchSizePlusOne intervals for settlement_item_id Item1
    Then the expected status should be returned

    # POST includes a duplicate of an interval that was posted in a previous POST.
    Given I reset the intervals start date and flags
    Given I expect the next API call to return a status code of 400 and details of "interval already exists for this settlement item id"
    Given I POST a set of 10 intervals for settlement_item_id Item1
    Then the expected status should be returned

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # Cleanup
    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 200 settlement item intervals


  Scenario: GET per_page and page

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for interval performance |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given I POST a set of 10 intervals for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    # per_page = number of intervals + 1
    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: 11 direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # per_page = number of intervals
    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: 10 direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # per_page = number of intervals - 1
    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: 9 direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # per_page = 1
    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: 1 direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # backward paging
    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: 9 direction: backward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: 1 direction: backward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # Cleanup
    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 10 settlement item intervals


  Scenario: PUT: update some intervals

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-10-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for interval performance |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-10-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given I POST a set of 100 intervals for settlement_item_id Item1

    Given I PUT an update for some of the intervals with settlement_item_id Item1
    And changes should be recorded in the settlement_item_intervals audit log

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # Payload contains an interval with an unknown timestamp. Entire PUT should fail.
    Given I want to include an interval with an unknown timestamp
    Given I expect the next API call to return a status code of 400 and details of "interval does not exist"
    Given I PUT an update for all of the intervals with settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Payload contains intervals with duplicate timestamps. Entire PUT should fail.
    Given I want to include a duplicate interval from the first batch
    Given I expect the next API call to return a status code of 400 and details of "all interval_dttm_utc must be unique"
    Given I PUT an update for some of the intervals with settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Payload contains intervals with bad enumeration. Entire PUT should fail.
    Given I want to include an interval with a bad enumeration
    Given I expect the next API call to return a status code of 400 and details of "Invalid interval_source"
    Given I PUT an update for some of the intervals with settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Above tests corrupted our existing interval set, so we need to start fresh with another item
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-10-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item2
    Given I POST a set of 100 intervals for settlement_item_id Item2

    # Payload contains an interval with a different settlement_item_id. Entire PUT should fail.
    Given I want to include an interval with a random settlement item id
    Given I expect the next API call to return a status code of 400 and details of "all settlement_item_id must be the same"
    Given I PUT an update for some of the intervals with settlement_item_id Item2
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Cleanup
    Given I DELETE the settlement


  Scenario: PUT: update all intervals

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for interval performance |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals_summary
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the expected status should be returned

    # batchSizeMinusOne
    Given I POST a set of batchSizeMinusOne intervals for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I PUT an update for all of the intervals with settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals

    # batchSize
    Given I POST a set of batchSize intervals for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I PUT an update for all of the intervals with settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals

    # batchSizePlusOne
    Given I POST a set of batchSizePlusOne intervals for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I PUT an update for all of the intervals with settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals

    # Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 0 settlement item intervals


  Scenario: PATCH: update all or some intervals

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | QAA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: PATCH: update all intervals |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given I POST a set of 20 intervals for settlement_item_id Item1

    # PATCH all fields on all intervals
    Given I PATCH an update for all of the intervals with settlement_item_id Item1
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals
    And changes should be recorded in the settlement_item_intervals audit log

    # PATCHing one field has slightly different code path than patching all fields
    Given I only want to patch one field
    Given I PATCH an update for some of the intervals with settlement_item_id Item1
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals
    And changes should be recorded in the settlement_item_intervals audit log
    Given I reset the intervals start date and flags

    # Payload contains intervals with different fields. Entire PATCH should fail.
    Given I want to patch different fields
    Given I expect the next API call to return a status code of 400 and details of "all intervals must have the same set of fields to patch"
    Given I PATCH an update for all of the intervals with settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Payload contains an interval with an unknown timestamp. Entire PATCH should fail.
    Given I want to include an interval with an unknown timestamp
    Given I expect the next API call to return a status code of 400 and details of "interval does not exist"
    Given I PATCH an update for all of the intervals with settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Payload contains an interval with a different settlement_item_id. Entire PATCH should fail.
    Given I want to include an interval with a random settlement item id
    Given I expect the next API call to return a status code of 400 and details of "all settlement_item_id must be the same"
    Given I PATCH an update for all of the intervals with settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Payload contains intervals with duplicate timestamps. Entire PATCH should fail.
    Given I want to include a duplicate interval from the first batch
    Given I expect the next API call to return a status code of 400 and details of "all interval_dttm_utc must be unique"
    Given I PATCH an update for all of the intervals with settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Payload contains intervals with bad enumeration. Entire PATCH should fail.
    Given I want to include an interval with a bad enumeration
    Given I expect the next API call to return a status code of 400 and details of "Invalid metered_uom"
    Given I PATCH an update for all of the intervals with settlement_item_id Item1
    Then the expected status should be returned
    Given I reset the intervals start date and flags

    # Re-verify the audit log
    And changes should be recorded in the settlement_item_intervals audit log

    # Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 20 settlement item intervals

