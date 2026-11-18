Feature: Audit logs


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Settlement audit log

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | Audit log test                              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: audit log |
      | settlement_status       | AWAITING_DATA                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
      | processing_status       |   FOO   |
    Then the response should include the new settlement

    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | PRELIMINARY        |
      | change_comments   | First update    |

    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type   | EVENT |
      | settlement_subtype      | Test TVA event                           |
      | start_dttm_utc          | 2023-09-08T11:00:00Z                |
      | end_dttm_utc            | 2023-09-08T11:30:00Z                |
      | event_id                | <uuid>                                   |
      | settlement_status       | FINALIZED                         |
      | business_process_status | IN_PROCESS                         |
      | processing_status       |   BAR   |
      | change_comments   | Second update    |
    Then the response should include the updated settlement

    And I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | AWAITING_DATA        |
      | change_comments   | Third update    |

    Given I DELETE the settlement
    Then all of the following stepdefs should pass:
    * the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    * changes should be recorded in the settlement audit log with per_page: 4 direction: forward
    * changes should be recorded in the settlement audit log with per_page: 4 direction: backward


  Scenario: Settlement item audit log

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | Audit log test                              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: audit log |
      | settlement_status       | AWAITING_DATA                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id |    <uuid>                  |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                     |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to PRELIMINARY for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_item_status | PRELIMINARY               |
      | change_comments        | First update  |
    Then the expected status should be returned

    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | METER                       |
      | settlement_level_id    | <uuid> |
      | submitted_indicator    | false                       |
      | settlement_item_status | AWAITING_DATA                     |
      | atlas_settlement_level_id                      |    <uuid>                  |
      | asset_type             | DER_BESS                    |
      | start_dttm_utc          | 2023-09-05T08:10:00Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                     |
      | change_comments        | Second update      |
    Then the response should include the updated settlement_item

    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | ACCOUNT                       |
      | settlement_level_id    | <uuid> |
      | submitted_indicator    | true                       |
      | settlement_item_status | AWAITING_DATA                     |
      | atlas_settlement_level_id                      |    <uuid>                  |
      | asset_type             | LOAD_APPARENT                    |
      | start_dttm_utc          | 2023-09-05T08:20:00Z                     |
      | end_dttm_utc            | 2023-09-05T08:40:00Z                     |
      | change_comments        | Third update      |
    Then the response should include the updated settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to PRELIMINARY for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_item_status | PRELIMINARY               |
      | change_comments        | Fourth update  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to FINALIZED for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_item_status | FINALIZED               |
      | change_comments        | Fifth update  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to NO_DATA for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_item_status | NO_DATA               |
      | change_comments        | Sixth update  |
    Then the expected status should be returned

    Given I DELETE the settlement
    # Note: if you have to change this value, you must also change the per_page values below based on the comments
    And I expect the audit log to return a total of 20 entries
    Then all of the following stepdefs should pass:
    * the DELETE settlement details should specify 1 settlement items and 0 settlement item intervals
    # Following stepdef results in one page being returned
    * changes should be recorded in the settlement_item audit log with per_page: 100 direction: forward
    # Following stepdef results in one page being returned, with number of entries = per_page
    * changes should be recorded in the settlement_item audit log with per_page: 20 direction: forward
    # Following stepdef results in last page having 1 entry
    * changes should be recorded in the settlement_item audit log with per_page: 19 direction: forward
    * changes should be recorded in the settlement_item audit log with per_page: 19 direction: backward
    # Following stepdef results in last page having 2 entries
    * changes should be recorded in the settlement_item audit log with per_page: 18 direction: forward
    * changes should be recorded in the settlement_item audit log with per_page: 18 direction: backward
    # Following stepdef results in two pages, each with number of entries = per_page
    * changes should be recorded in the settlement_item audit log with per_page: 10 direction: forward
    * changes should be recorded in the settlement_item audit log with per_page: 10 direction: backward
    # Minimum per_page
    * changes should be recorded in the settlement_item audit log with per_page: 1 direction: forward
    * changes should be recorded in the settlement_item audit log with per_page: 1 direction: backward


  Scenario: Settlement item intervals audit log page sizes

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: intervals audit log page sizes |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id |    <uuid>                  |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    # We do two PUT statements to generate at least two unique sets for audit log entry timestamps
    Given I do all of the following:
    * I POST a set of 2 intervals for settlement_item_id Item1
    * I PUT an update for all of the intervals with settlement_item_id Item1
    * I PUT an update for all of the intervals with settlement_item_id Item1

    Then all of the following stepdefs should pass:
    * changes should be recorded in the settlement_item_intervals audit log with per_page: 2 direction: forward
    * changes should be recorded in the settlement_item_intervals audit log with per_page: 2 direction: backward
    * changes should be recorded in the settlement_item_intervals audit log with per_page: 10 direction: forward
    * changes should be recorded in the settlement_item_intervals audit log with per_page: 10 direction: backward

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals
    And changes should be recorded in the settlement_item_intervals audit log with per_page: 20 direction: forward

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 0 settlement item intervals


  Scenario: Settlement item intervals large audit log

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: large intervals audit log |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id |    <uuid>                  |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    # We do two PUT statements to generate at least two unique sets for audit log entry timestamps
    Given I do all of the following:
    * I POST a set of 500 intervals for settlement_item_id Item1
    * I PUT an update for all of the intervals with settlement_item_id Item1
    * I PUT an update for all of the intervals with settlement_item_id Item1

    Then all of the following stepdefs should pass:
    * changes should be recorded in the settlement_item_intervals audit log with per_page: 100000 direction: forward
    * changes should be recorded in the settlement_item_intervals audit log with per_page: 1000 direction: forward
    * changes should be recorded in the settlement_item_intervals audit log with per_page: 1000 direction: backward

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals
    And changes should be recorded in the settlement_item_intervals audit log with per_page: 5000 direction: forward

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 0 settlement item intervals


  Scenario: Settlement item interval: verify that changes for all properties are logged

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-10-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: verify that changes for all properties are logged |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id |    <uuid>                  |
      | start_dttm_utc          | 2023-10-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-05T08:30:00Z                     |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-10-05T08:05:00Z      |
      | interval_source          | MEASURED                  |
      | user_estimated           | true                      |
      | utility_data             | true                      |
      | relevant_indicator       | true                      |
      | vee_estimated            | true                     |
      | metered_value            | 123.45                    |
      | metered_uom              | KW                        |
      | baseline_value           | 7.8                       |
      | baseline_uom             | KWH                       |
      | nomination_value         | 100.5                     |
      | nomination_uom           | MW                        |
      | payment_nomination_value | 200.6                     |
      | payment_nomination_uom   | AMPS                        |
      | revenue_value            | 500.8                     |
      | currency         | USD                       |
      | payment_value            | 9.3                       |
      | market_quality_good      | true                      |
      | state_of_charge          | 0.4                |
      | payment_penalty_input_value                         |    56.78                |
      |   payment_penalty_input_uom                       |    KWH                |
      |      payment_penalty_value                    |    9.873                |
      |  payment_penalty_notes                       |   Did not meet performance                 |
      | original_offer_kw                            |       926.43                                     |
      | cleared_offer_kw                            |       510.00                                     |
      | revenue_value_estimated            | 532.04                     |
      | payment_value_estimated            | 467.00                     |
      | realtime_availability_kw            | 600.5                     |
      | is_armed            | true                     |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id          | <last-settlement-item-id> |
      | interval_dttm_utc           | 2023-10-05T08:05:00Z      |
      | interval_source             | UTILITY_TRANSFORM         |
      | user_estimated              | false                     |
      | utility_data                | false                     |
      | relevant_indicator          | false                     |
      | vee_estimated               | false                     |
      | metered_value               | 7834.6                    |
      | metered_uom                 | KWH                       |
      | baseline_value              | 9.2                       |
      | baseline_uom                | KW                        |
      | nomination_value            | 200.78                    |
      | nomination_uom              | AMPS                      |
      | payment_nomination_value    | 93.4                      |
      | payment_nomination_uom      | MW                        |
      | revenue_value               | 1.3                       |
      | currency                    | TWD                       |
      | payment_value               | 4.5                       |
      | market_quality_good         | false                     |
      | state_of_charge             | 0.82                      |
      | payment_penalty_input_value | 1                         |
      | payment_penalty_input_uom   | KW                        |
      | payment_penalty_value       | 10.4                      |
      | payment_penalty_notes       | Inadequate performance        |
      | original_offer_kw                            |      52676.43                                     |
      | cleared_offer_kw                            |       610.50                                     |
      | revenue_value_estimated            | 98.04                     |
      | payment_value_estimated            | 1005.00                     |
      | realtime_availability_kw            | 630.5                     |
      | is_armed            | false                     |
      | change_comments             | All fields changed        |
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    And changes should be recorded in the settlement_item_intervals audit log with per_page: 1000 direction: forward

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals
