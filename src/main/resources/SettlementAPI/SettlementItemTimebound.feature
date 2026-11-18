Feature: Settlement item timebound API

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  Scenario: POST with full optional field set, GET list, cleanup
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA timebound full      |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | TB Item 1            |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag Item1

    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id                 | <Item1>                |
      | start_dttm_utc                      | 2023-09-05T09:00:00Z   |
      | end_dttm_utc                        | 2023-09-05T10:00:00Z   |
      | interval_source                     | MEASURED               |
      | nomination_value                    | 100.5                  |
      | nomination_uom                      | MW                     |
      | payment_nomination_value            | 200.6                  |
      | payment_nomination_uom              | AMPS                   |
      | payment_nomination_value_estimated  | 210.0                  |
      | payment_nomination_uom_estimated    | AMPS                   |
      | revenue_value                       | 500.80                 |
      | payment_value                       | 9.30                   |
      | payment_penalty_input_value         | -56.78                 |
      | payment_penalty_input_uom           | KWH                    |
      | payment_penalty_value               | 9.873                  |
      | payment_penalty_notes               | Did not meet performance |
      | currency                            | USD                    |
      | change_comments                     | create row A full      |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_A

    When I call GET settlement_item_timebound with settlement_item_id: <Item1> start_dttm_utc: missing end_dttm_utc: missing per_page: 50 direction: forward
    Then GET settlement_item_timebound should return only expected active rows
    And the settlement_item_timebound response should be paged

    # cleanup
    When I DELETE settlement_item_timebound with id tag TB_A
    Then the expected status should be returned
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: POST with explicit nulls for optional fields
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA timebound nulls     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | TB Item 1b           |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag Item1b


    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id         | <Item1b>              |
      | start_dttm_utc              | 2023-09-05T09:00:00Z |
      | end_dttm_utc                | 2023-09-05T10:00:00Z |
      | interval_source             | MEASURED             |
      | nomination_value            | <null>               |
      | nomination_uom              | <null>               |
      | payment_nomination_value    | <null>               |
      | payment_nomination_uom      | <null>               |
      | revenue_value               | <null>               |
      | payment_value               | <null>               |
      | payment_penalty_input_value | <null>               |
      | payment_penalty_input_uom   | <null>               |
      | payment_penalty_value       | <null>               |
      | payment_penalty_notes       | <null>               |
      | currency                    | <null>               |
      | change_comments             | create row with nulls |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_NULLS

    # cleanup
    When I DELETE settlement_item_timebound with id tag TB_NULLS
    Then the expected status should be returned
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: POST negative validations
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA timebound negative  |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | TB Item 1c           |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag Item1c

    # end <= start
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item1c>              |
      | start_dttm_utc     | 2023-09-05T10:00:00Z  |
      | end_dttm_utc       | 2023-09-05T09:00:00Z  |
      | interval_source    | MEASURED               |
      | change_comments    | invalid time range     |
    Then the expected status should be returned

    # invalid interval_source
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item1c>              |
      | start_dttm_utc     | 2023-09-05T09:00:00Z  |
      | end_dttm_utc       | 2023-09-05T10:00:00Z  |
      | interval_source    | NOT_A_REAL_SOURCE      |
      | change_comments    | invalid interval_source |
    Then the expected status should be returned

    # invalid currency
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item1c>              |
      | start_dttm_utc     | 2023-09-05T09:00:00Z  |
      | end_dttm_utc       | 2023-09-05T10:00:00Z  |
      | interval_source    | MEASURED               |
      | currency           | NOT_A_CURRENCY         |
      | change_comments    | invalid currency       |
    Then the expected status should be returned

    # invalid uom
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item1c>              |
      | start_dttm_utc     | 2023-09-05T09:00:00Z  |
      | end_dttm_utc       | 2023-09-05T10:00:00Z  |
      | interval_source    | MEASURED               |
      | nomination_uom     | not_a_uom              |
      | change_comments    | invalid uom            |
    Then the expected status should be returned

    # nonexistent settlement_item_id
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <uuid>                |
      | start_dttm_utc     | 2023-09-05T09:00:00Z  |
      | end_dttm_utc       | 2023-09-05T10:00:00Z  |
      | interval_source    | MEASURED               |
      | change_comments    | nonexistent item       |
    Then the expected status should be returned

    # cleanup
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: GET by id include_deleted behavior + POST after DELETE
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA include_deleted     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | TB Item 2            |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag Item2


    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item2>              |
      | start_dttm_utc     | 2023-09-05T12:00:00Z |
      | end_dttm_utc       | 2023-09-05T13:00:00Z |
      | interval_source    | MEASURED             |
      | change_comments    | create row C         |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_C

    When I DELETE settlement_item_timebound with id tag TB_C
    Then the expected status should be returned

    Given I set include_deleted=missing
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound for id tag TB_C
    Then the expected status should be returned

    Given I set include_deleted=true
    When I call GET settlement_item_timebound for id tag TB_C
    Then GET settlement_item_timebound by id should match saved row TB_C

    # Recreate after soft delete (allowed)
    Given I set include_deleted=missing
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item2>              |
      | start_dttm_utc     | 2023-09-05T12:00:00Z |
      | end_dttm_utc       | 2023-09-05T13:00:00Z |
      | interval_source    | MEASURED             |
      | change_comments    | recreate after delete |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_C_RECREATED

    # cleanup
    When I DELETE settlement_item_timebound with id tag TB_C_RECREATED
    Then the expected status should be returned
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: GET by id negative validations
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound for id <uuid>
    Then the expected status should be returned


    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound for id not-a-uuid
    Then the expected status should be returned

  Scenario: GET list negative validations
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with missing settlement_item_id
    Then the expected status should be returned

  Scenario: Overlap rejection for POST (same request), PUT, PATCH
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA overlap rejection   |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | TB Item 3            |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag Item3


    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item3>              |
      | start_dttm_utc     | 2023-09-05T14:00:00Z |
      | end_dttm_utc       | 2023-09-05T15:00:00Z |
      | interval_source    | MEASURED             |
      | change_comments    | baseline row         |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_BASE


    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item3>              |
      | start_dttm_utc     | 2023-09-05T14:30:00Z |
      | end_dttm_utc       | 2023-09-05T15:30:00Z |
      | interval_source    | MEASURED             |
      | change_comments    | overlap post         |
    Then the expected status should be returned


    And I expect the next API call to return a status code of 200 and message of "OK"
    When I PUT settlement_item_timebound with id tag TB_BASE and values:
      | settlement_item_id | <Item3>              |
      | start_dttm_utc     | 2023-09-05T14:30:00Z |
      | end_dttm_utc       | 2023-09-05T15:30:00Z |
      | interval_source    | MEASURED             |
      | change_comments    | overlap put          |
    Then the expected status should be returned


    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_BASE and values:
      | start_dttm_utc  | 2023-09-05T14:30:00Z |
      | end_dttm_utc    | 2023-09-05T15:30:00Z |
      | change_comments | overlap patch         |
    Then the expected status should be returned

    # cleanup
    When I DELETE settlement_item_timebound with id tag TB_BASE
    Then the expected status should be returned
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: PUT and PATCH negative validations
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA PUT PATCH negative  |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | TB Item 3b           |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag Item3b

    # Missing id in PUT
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with missing id and values:
      | settlement_item_id | <Item3b>              |
      | start_dttm_utc     | 2023-09-05T14:00:00Z  |
      | end_dttm_utc       | 2023-09-05T15:00:00Z  |
      | change_comments    | missing id            |
    Then the expected status should be returned

    # Missing id in PATCH
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with missing id and values:
      | currency        | USD          |
      | change_comments | missing id   |
    Then the expected status should be returned

    # Nonexistent id in PUT
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id <uuid> and values:
      | settlement_item_id | <Item3b>              |
      | start_dttm_utc     | 2023-09-05T14:00:00Z  |
      | end_dttm_utc       | 2023-09-05T15:00:00Z  |
      | change_comments    | nonexistent id        |
    Then the expected status should be returned

    # cleanup
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: DELETE negative validations
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I DELETE settlement_item_timebound with id <uuid>
    Then the expected status should be returned

  Scenario: Audit endpoint is paged and keyed only by settlement_item_timebound_id
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA audit paging        |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | TB Item 4            |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag Item4


    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <Item4>              |
      | start_dttm_utc     | 2023-09-05T16:00:00Z |
      | end_dttm_utc       | 2023-09-05T17:00:00Z |
      | interval_source    | MEASURED             |
      | change_comments    | create row D         |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_D

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_D and values:
      | currency        | USD       |
      | change_comments | patch row D |
    Then the expected status should be returned

    When I DELETE settlement_item_timebound with id tag TB_D
    Then the expected status should be returned

    When I call GET settlement_item_timebound_audit for id tag TB_D per_page 1 direction forward
    Then settlement_item_timebound audit should contain at least 1 entries
    And settlement_item_timebound audit response should be paged
    And settlement_item_timebound audit entries should not contain settlement_item_id or timestamp columns

    # cleanup
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
