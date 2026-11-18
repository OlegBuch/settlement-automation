Feature: Feature test for settlement item intervals

  Reference: <CONFLUENCE_URL>/display/PMENA/Settlement+API+-+Technical+Design
  ITAPPSIT-3760: settlement api: add new db columns and new API fields for FCAS
  ITAPPSIT-4063: introduce inputs_available_until_dttm_utc field for settlements and is_active column for settlement_items and settlement_item_intervals

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Basic scenario for settlement item intervals

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-06T08:00:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for settlement hierarchy |
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
      | atlas_settlement_level_id                      |    <uuid>                  |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-06T08:00:00Z                     |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals_summary
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the expected status should be returned

    And no entries should be found in the settlement_item_intervals audit log

    # Post an interval with mandatory properties only
    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T09:00:00Z  |
      | interval_source          | MEASURED                     |
      | user_estimated           | true                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    # Since v1 POST doesn't return entity, call GET to verify interval has been created
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

      # Summary finds only one interval
    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    # PUT: update mandatory properties
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T09:00:00Z  |
      | interval_source          | UTILITY                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | false                      |
      | change_comments          | Update some properties     |
    Then the expected status should be returned

    # PUT: certain properties are ignored
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T09:00:00Z  |
      | interval_source          | INTERPOLATION                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | false                      |
      | deleted                  | false                       |
      |last_updated_by           | <uuid>                     |
      |last_updated_dttm_utc     |    2023-09-05T10:00:00Z                        |
      |    created_dttm_utc                      |             2023-09-05T10:00:00Z                                   |
      | change_comments          | Ignore some properties     |
    Then the expected status should be returned

    # Since v1 PUT doesn't return updated entity, call GET to verify interval has been updated
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # Verify audit log entries. Note: per agreement with Yanis, change_comments are not recorded in audit log for intervals
    And changes should be recorded in the settlement_item_intervals audit log

    # POST: all supported properties
    # All booleans are posted as TRUE because model defaults are all FALSE
    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T09:30:00Z      |
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
    | payment_penalty_input_value                         |    -56.78                |
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


    # POST: all supported properties, some explicitly set to null
    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T09:35:00Z      |
      | interval_source          | MEASURED                  |
      | user_estimated           | true                      |
      | utility_data             | true                      |
      | relevant_indicator       | true                      |
      | vee_estimated            | <null>                     |
      | metered_value            | 123.45                    |
      | metered_uom              | KW                        |
      | baseline_value           | <null>                       |
      | baseline_uom             | <null>                       |
      | nomination_value         | 100.5                     |
      | nomination_uom           | MW                        |
      | payment_nomination_value | 200.6                     |
      | payment_nomination_uom   | AMPS                        |
      | revenue_value            | 500.8                     |
      | currency         | <null>                       |
      | payment_value            | 9.3                       |
      | market_quality_good      | <null>                      |
      | state_of_charge          | 0.4                |
      | payment_penalty_input_value                         |    <null>                |
      |   payment_penalty_input_uom                       |    <null>                |
      |      payment_penalty_value                    |    <null>                |
      |  payment_penalty_notes                       |   <null>                 |
      | original_offer_kw                            |       <null>                                      |
      | cleared_offer_kw                            |       <null>                                      |
      | revenue_value_estimated            | <null>                     |
      | payment_value_estimated            | <null>                     |
      | realtime_availability_kw            | <null>                     |
      | is_armed            | true                     |
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # Summary finds three intervals
    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    # Cannot post an interval with the same timestamp as an existing interval
    Given  I expect the next API call to return a status code of 400 and details of "interval already exists for this settlement item id"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T09:35:00Z  |
      | interval_source          | MEASURED                     |
      | user_estimated           | false                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    # Cannot PUT a new interval (no existing interval with the specified timestamp)
    Given  I expect the next API call to return a status code of 400 and details of "interval does not exist - try using POST instead"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T10:00:00Z  |
      | interval_source          | UTILITY                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | false                      |
      | change_comments          | Update some properties     |
    Then the expected status should be returned


    # Settlement item not found
    Given  I expect the next API call to return a status code of 404 and details of "Cannot find SettlementItem for settlement_item_id"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <uuid> |
      | interval_dttm_utc        | 2019-07-25T08:30:00Z  |
      | interval_source          | MEASURED                     |
      | user_estimated           | true                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    # Invalid uom
    Given  I expect the next API call to return a status code of 400 and details of "Invalid metered_uom.  Choose from:"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T10:30:00Z      |
      | interval_source          | MEASURED                  |
      | user_estimated           | true                      |
      | utility_data             | true                      |
      | relevant_indicator       | true                      |
      | metered_uom          | kWh                |

    # Invalid state-of-charge
    Given  I expect the next API call to return a status code of 400 and details of "state of charge must be between 0.0 and 1.0 inclusive"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T10:30:00Z      |
      | interval_source          | MEASURED                  |
      | user_estimated           | true                      |
      | utility_data             | true                      |
      | relevant_indicator       | true                      |
      | state_of_charge          | 1234567.89                |

  # DELETE item (v0 appears to include failed POSTs in DELETE total)
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 3 settlement item intervals
    And changes should be recorded in the settlement_item audit log

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals_summary
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the expected status should be returned

    Given  I expect the next API call to return a status code of 404 and details of "Cannot find SettlementItem for settlement_item_id"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T10:35:00Z  |
      | interval_source          | MEASURED                     |
      | user_estimated           | true                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    Given  I expect the next API call to return a status code of 404 and details of "Cannot find SettlementItem for settlement_item_id"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T09:35:00Z  |
      | interval_source          | MARKET_INTEGRATION                     |
      | user_estimated           | true                     |
      | utility_data            | false                     |
      | relevant_indicator       | false                      |
      | change_comments          | Update some properties     |
    Then the expected status should be returned

  # Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log



    Scenario: ITAPPSIT-3329: create PATCH /settlement_item_intervals endpoint

      When I POST a settlement with the following properties:
        | settlement_type         | ONGOING_DATA_SUBMISSION                  |
        | settlement_subtype      | TVA event                                |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-06T08:00:00Z                     |
        | event_id                | <uuid>                                   |
        | description             | QAA test: Basic scenario for settlement hierarchy |
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
        | atlas_settlement_level_id                      |    <uuid>                  |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-06T08:00:00Z                     |
      Then the response should include the new settlement_item

      # POST: all supported properties
    # All booleans are posted as TRUE because model defaults are all FALSE
      # deleted=false is ignored
      Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T08:05:00Z      |
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
        | payment_penalty_input_value                         |    -56.78                |
        |   payment_penalty_input_uom                       |    KWH                |
        |      payment_penalty_value                    |    9.873                |
        |  payment_penalty_notes                       |   Did not meet performance                 |
        | deleted                                             | false                 |
        | original_offer_kw                            |       926.43                                     |
        | cleared_offer_kw                            |       510.00                                     |
        | revenue_value_estimated            | 582.45                     |
        | payment_value_estimated            | 437.0                    |
        | realtime_availability_kw            | 700.5                     |
        | is_armed            | true                     |
      Then the expected status should be returned

      # PATCH: Minimal payload

      Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
      When I PATCH the settlement_item_interval with new values:
        | settlement_item_id | <last-settlement-item-id>         |
        | interval_dttm_utc  | 2023-09-05T08:05:00Z               |
        | payment_penalty_value |    78.0  |
        | change_comments    | Update payment_penalty_value |
      Then the expected status should be returned
      When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
      Then the GET settlement_item_intervals response should contain only non-deleted intervals
      And changes should be recorded in the settlement_item_intervals audit log

      # PATCH: Update all allowed properties

      Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
      When I PATCH the settlement_item_interval with new values:
        | settlement_item_id | <last-settlement-item-id>         |
        | interval_dttm_utc  | 2023-09-05T08:05:00Z               |
        | interval_source    | MARKET_INTEGRATION                          |
        | user_estimated     | false                             |
        | utility_data       | false                             |
        | relevant_indicator | false                             |
        | vee_estimated            | false                     |
        | metered_value            | 3474                    |
        | metered_uom              | KWH                        |
        | baseline_value           | 10.45                       |
        | baseline_uom             | AMPS                       |
        | nomination_value         | 230.5                     |
        | nomination_uom           | KW                        |
        | payment_nomination_value | 5.6                     |
        | payment_nomination_uom   | KWH                        |
        | revenue_value            | 1000.87                     |
        | currency         | TWD                       |
        | payment_value            | 14.3                       |
        | market_quality_good      | false                      |
        | state_of_charge          | 0.86                |
        | payment_penalty_input_value                         |    -401.6                |
        |   payment_penalty_input_uom                       |    AMPS                |
        |      payment_penalty_value                    |    78.0                |
        |  payment_penalty_notes                       |   Gave a warning                 |
        | original_offer_kw                            |       8.2                                     |
        | cleared_offer_kw                            |       7.4                                     |
        | revenue_value_estimated            | 24.0                     |
        | payment_value_estimated            | 5.7                     |
        | realtime_availability_kw            | 37.8                     |
        | is_armed            | false                     |
        | change_comments    | Update all allowed properties with PATCH |
      Then the expected status should be returned
      When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
      Then the GET settlement_item_intervals response should contain only non-deleted intervals
      And changes should be recorded in the settlement_item_intervals audit log

      # Unsupported fields are stripped out

      Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
      When I PATCH the settlement_item_interval with new values:
        | settlement_item_id | <last-settlement-item-id>         |
        | interval_dttm_utc  | 2023-09-05T08:05:00Z               |
        | interval_source    | VENDOR_METERING                          |
        | last_updated_by | foo                      |
        | last_updated_dttm_utc |   2023-09-10T09:00:00Z                  |
        | created_dttm_utc      |         2023-09-10T09:00:00Z                                |
        | change_comments    | Unsupported fields are stripped out |
        | deleted                                             | false                 |
      Then the expected status should be returned
      When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
      Then the GET settlement_item_intervals response should contain only non-deleted intervals
      And changes should be recorded in the settlement_item_intervals audit log

      # PATCH errors

      Given I expect the next API call to return a status code of 400 and details of "interval does not exist - try using POST instead"
      When I PATCH the settlement_item_interval with new values:
        | settlement_item_id | <last-settlement-item-id>         |
        | interval_dttm_utc  | 2030-07-25T08:35:00Z              |
        | interval_source    | MARKET_INTEGRATION                          |
        | user_estimated     | false                             |
        | change_comments    | Interval not found |
      Then the expected status should be returned

      Given I expect the next API call to return a status code of 400 and details of "must have required property 'interval_dttm_utc'"
      When I PATCH the settlement_item_interval with new values:
        | settlement_item_id | <last-settlement-item-id>         |
        | interval_source    | MARKET_INTEGRATION                          |
        | user_estimated     | false                             |
        | change_comments    | Missing mandatory field |
      Then the expected status should be returned

      # Cleanup
      When I DELETE the settlement
      Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals
      And changes should be recorded in the settlement audit log
      And changes should be recorded in the settlement_item_intervals audit log


  Scenario: No Settlement item interval can be created or updated for FINALIZED settlement item

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-06T08:00:00Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA Test             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id                      |    <uuid>                  |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-06T08:00:00Z           |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-06T00:00:00Z   |
      | interval_source          | MEASURED                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    # Change the item status to FINALIZED
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA test             |
      | submitted_indicator    | true                 |
      | settlement_item_status | FINALIZED                  |
      | asset_type             | LOAD                 |
      | change_comments        | AWAITING_DATA -> FINALIZED |
    Then the response should include the updated settlement_item
    And changes should be recorded in the settlement_item audit log

    # Now you cannot post a new interval
    Given  I expect the next API call to return a status code of 400 and details of "cannot insert settlement intervals when the settlement item status=FINALIZED"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-06T01:00:00Z  |
      | interval_source          | MEASURED                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    # And you cannot update an existing interval
    Given I expect the next API call to return a status code of 400 and details of "Cannot update intervals for a SettlementItem that is FINALIZED"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-06T00:00:00Z  |
      | interval_source          | UTILITY                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | false                      |
      | change_comments          | Update some properties     |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "Cannot update intervals for a SettlementItem that is FINALIZED"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id | <last-settlement-item-id>         |
      | interval_dttm_utc  | 2023-09-06T00:00:00Z             |
      | interval_source    | MARKET_INTEGRATION                          |
      | change_comments    | Cannot update interval |
    Then the expected status should be returned

    # However, you can post and update intervals for an item in the NO_DATA state
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA Test 2            |
      | submitted_indicator    | true                 |
      | settlement_item_status | NO_DATA        |
      | asset_type             | LOAD                 |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2019-07-25T08:30:00Z  |
      | interval_source          | MEASURED                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2019-07-25T08:30:00Z  |
      | interval_source          | UTILITY                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | false                      |
      | change_comments          | Update some properties     |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id | <last-settlement-item-id>         |
      | interval_dttm_utc  | 2019-07-25T08:30:00Z              |
      | interval_source    | MARKET_INTEGRATION                          |
      | change_comments    | Update interval_source |
    Then the expected status should be returned
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals
    And changes should be recorded in the settlement_item_intervals audit log

    # Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 2 settlement item intervals



  Scenario: Settlement item intervals can be deleted and re-created

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-12-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-12-06T08:00:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: re-create intervals |
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
      | atlas_settlement_level_id                      |    <uuid>                  |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-12-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-12-06T08:00:00Z                      |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given I POST a set of 2 intervals for settlement_item_id Item1

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals
    And changes should be recorded in the settlement_item_intervals audit log

    Given I reset the intervals start date and flags
    Given I POST a set of 2 intervals for settlement_item_id Item1
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct
    # This scenario returns an audit log which is too complicated for this stepdef
    #And changes should be recorded in the settlement_item_intervals audit log

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 2 settlement item intervals


   # ITAPPSIT-3347: settlement API incorrectly omitting 0-value fields from GET /intervals response
    Scenario: Zero-valued numeric fields

      When I POST a settlement with the following properties:
        | settlement_type         | ONGOING_DATA_SUBMISSION                  |
        | settlement_subtype      | Zero-valued event                                |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-06T08:00:00Z                     |
        | event_id                | <uuid>                                   |
        | description             | QAA test: Zero-valued numeric fields |
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
        | atlas_settlement_level_id                      |    <uuid>                  |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-06T08:00:00Z                     |
        | asset_type             | LOAD                 |
      Then the response should include the new settlement_item

    # POST: zero-valued numeric properties
      Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T09:00:00Z     |
        | interval_source          | MEASURED                  |
        | user_estimated           | true                      |
        | utility_data             | true                      |
        | relevant_indicator       | true                      |
        | vee_estimated            | <null>                     |
        | metered_value            | 0.0                    |
        | metered_uom              | KW                        |
        | baseline_value           | 0.0                       |
        | baseline_uom             | <null>                       |
        | nomination_value         | 0.0                     |
        | nomination_uom           | MW                        |
        | payment_nomination_value | 0.0                     |
        | payment_nomination_uom   | AMPS                        |
        | revenue_value            | 0.0                     |
        | currency         | USD                       |
        | payment_value            | 0.0                       |
        | state_of_charge          | 0.0                |
      | payment_penalty_value    | 0.0                |
        | payment_penalty_input_value                         |    0.0                |
        | original_offer_kw    | 0.0                |
        | cleared_offer_kw                         |    0.0                |
        | revenue_value_estimated            | 0.0                     |
        | payment_value_estimated            | 0.0                     |
        | realtime_availability_kw            | 0.0                     |
      Then the expected status should be returned

      #PUT: zero-valued numeric properties
      # First, POST an interval with non-zeros, then PUT zeros
      Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T10:00:00Z     |
        | interval_source          | MEASURED                  |
        | user_estimated           | true                      |
        | utility_data             | true                      |
        | relevant_indicator       | true                      |
        | metered_value            | 10.0                    |
        | metered_uom              | KW                        |
        | baseline_value           | 20.0                       |
        | baseline_uom             | <null>                       |
        | nomination_value         | 30.0                     |
        | nomination_uom           | MW                        |
        | payment_nomination_value | 40.0                     |
        | payment_nomination_uom   | AMPS                        |
        | revenue_value            | 50.0                     |
        | currency         | USD                       |
        | payment_value            | 60.0                       |
        | state_of_charge          | 0.5                |
        | payment_penalty_value    | 100.0                |
        | payment_penalty_input_value                         |    123.45                |
        | original_offer_kw    | 329               |
        | cleared_offer_kw                         |    40.2                |
        | revenue_value_estimated            | 24.8                     |
        | payment_value_estimated            | 5.7                     |
        | realtime_availability_kw            | 37.8                     |
      Then the expected status should be returned

      When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
      Then the GET settlement_item_intervals response should contain only non-deleted intervals

      Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
      When I PUT the settlement_item_interval with new values:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T10:00:00Z  |
        | interval_source          | UTILITY                     |
        | user_estimated           | false                     |
        | utility_data            | false                     |
        | relevant_indicator       | false                      |
        | change_comments          | Update numeric properties to zeros     |
        | metered_value            | 0.0                    |
        | baseline_value           | 0.0                       |
        | nomination_value         | 0.0                     |
        | payment_nomination_value | 0.0                     |
        | revenue_value            | 0.0                     |
        | payment_value            | 0.0                       |
        | state_of_charge          | 0.0                |
        | payment_penalty_value    | 0.0                |
        | payment_penalty_input_value                         |    0.0                |
        | original_offer_kw    | 0.0                |
        | cleared_offer_kw                         |    0.0                |
        | revenue_value_estimated            | 0.0                     |
        | payment_value_estimated            | 0.0                     |
        | realtime_availability_kw            | 0.0                     |
      Then the expected status should be returned

      # POST and PUT: small, negative, and large numeric properties
      Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T11:00:00Z      |
        | interval_source          | MEASURED                  |
        | user_estimated           | true                      |
        | utility_data             | true                      |
        | relevant_indicator       | true                      |
        | metered_value            | 214                    |
        | baseline_value           | 0.000001                       |
        | nomination_value         | -100.5                     |
        | payment_nomination_value | 989456738.2485768                     |
        | revenue_value            | 500.8                     |
        | payment_value            | 9.3                       |
        | state_of_charge          | 0.4                |
        | payment_penalty_value    | 0.0000004                |
        | payment_penalty_input_value                         |    0.0000005                 |
        | original_offer_kw    | 0.0000011               |
        | cleared_offer_kw                         |    0.0000008                |
         | revenue_value_estimated            | 0.0000001                     |
    | payment_value_estimated            | 0.0000002                     |
    | realtime_availability_kw            | 0.0000003                     |
      Then the expected status should be returned

      Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
      When I PUT the settlement_item_interval with new values:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T11:00:00Z  |
        | interval_source          | MEASURED                     |
        | user_estimated           | true                     |
        | utility_data            | true                     |
        | relevant_indicator       | true                      |
        | change_comments          | Update numeric properties to interesting values     |
        | metered_value            | 0.000002                    |
        | revenue_value            |       -0.05               |
        | payment_value            | -0979345730.9385765                       |
        | payment_penalty_value    | -988345730.93857634                |
        | payment_penalty_input_value                         |    939347730.9385712                 |
        | original_offer_kw    | -488345730.93857612                |
        | cleared_offer_kw                         |    889347730.9385757                |
        | revenue_value_estimated            | -765345730.93857423                     |
        | payment_value_estimated            | 582347730.9385204                     |
        | realtime_availability_kw            | 187347730.9385539                     |
      Then the expected status should be returned

      When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
      Then the GET settlement_item_intervals response should contain only non-deleted intervals

      When I call GET settlement_item_intervals_summary
      Then the GET settlement_item_intervals_summary result should be correct

  # Cleanup
      When I DELETE the settlement
      Then the DELETE settlement details should specify 1 settlement items and 3 settlement item intervals
      And changes should be recorded in the settlement audit log


  Scenario: Cannot set deleted status with POST, PUT, or PATCH

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | QAA event                                |
      | start_dttm_utc          | 2023-10-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-06T08:00:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Cannot set deleted status with POST, PUT, or PATCH |
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
      | atlas_settlement_level_id                      |    <uuid>                  |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-10-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-10-06T08:00:00Z                    |
    Then the response should include the new settlement_item

     # POST: cannot specify deleted=true
    Given I expect the next API call to return a status code of 400 and details of "may not specify deleted=true"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-10-05T09:00:00Z  |
      | interval_source          | MEASURED                     |
      | user_estimated           | true                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
     | deleted                  | true                      |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-10-05T09:00:00Z  |
      | interval_source          | MEASURED                     |
      | user_estimated           | true                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

       # PUT: cannot specify deleted=true
    Given I expect the next API call to return a status code of 400 and details of "may not specify deleted=true"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-10-05T09:00:00Z  |
      | interval_source          | UTILITY                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | false                      |
      | change_comments          | cannot specify deleted=true     |
      | deleted                  | true                      |
    Then the expected status should be returned

     # PATCH: cannot specify deleted=true
    Given I expect the next API call to return a status code of 400 and details of "may not specify deleted=true"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id | <last-settlement-item-id>         |
      | interval_dttm_utc  | 2023-10-05T09:00:00Z              |
      | payment_penalty_value |    78.0  |
      | change_comments          | cannot specify deleted=true     |
      | deleted                  | true                      |
    Then the expected status should be returned

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain all of the intervals including deleted

    # PUT: cannot specify deleted=false to un-delete an interval
    Given I expect the next API call to return a status code of 400 and details of "interval does not exist"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-10-05T09:00:00Z  |
      | interval_source          | UTILITY                     |
      | user_estimated           | false                     |
      | utility_data            | false                     |
      | relevant_indicator       | false                      |
      | change_comments          | Cannot update deleted interval     |
      | deleted                  | false                      |
    Then the expected status should be returned

      # PATCH: cannot specify deleted=false to un-delete an interval
    Given I expect the next API call to return a status code of 400 and details of "interval does not exist"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id | <last-settlement-item-id>         |
      | interval_dttm_utc  | 2023-10-05T09:00:00Z             |
      | interval_source    | MARKET_INTEGRATION                          |
      | change_comments    | Cannot update deleted interval |
      | deleted                  | false                      |
    Then the expected status should be returned

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain all of the intervals including deleted

    # Cleanup

    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 0 settlement item intervals


    Scenario: ITAPPSIT-3453: settlement API: Add validation of interval timestamp against parent item time range

      3453 enforces: item.start_dttm_utc < interval.interval_dttm_utc <= item.end_dttm_utc

      When I POST a settlement with the following properties:
        | settlement_type         | ONGOING_DATA_SUBMISSION                  |
        | settlement_subtype      | TVA event                                |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-06T08:00:00Z                     |
        | event_id                | <uuid>                                   |
        | description             | QAA test: Basic scenario for settlement hierarchy |
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
        | atlas_settlement_level_id                      |    <uuid>                  |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-06T08:00:00Z                     |
      Then the response should include the new settlement_item

      * -> Verify you cannot create an interval prior or equal to the item start
      Given I expect the next API call to return a status code of 400 and details of "interval_dttm_utc '2023-09-05T07:59:00Z' is before or equal to start date for settlement item"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T07:59:00Z  |
        | interval_source          | MEASURED                     |
        | user_estimated           | true                     |
        | utility_data            | true                     |
        | relevant_indicator       | true                      |
      Then the expected status should be returned

      Given I expect the next API call to return a status code of 400 and details of "interval_dttm_utc '2023-09-05T08:00:00Z' is before or equal to start date for settlement item"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T08:00:00Z  |
        | interval_source          | MEASURED                     |
        | user_estimated           | true                     |
        | utility_data            | true                     |
        | relevant_indicator       | true                      |
      Then the expected status should be returned

      * -> Verify you can create the first interval in the item range
      Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T08:01:00Z  |
        | interval_source          | MEASURED                     |
        | user_estimated           | true                     |
        | utility_data            | true                     |
        | relevant_indicator       | true                      |
      Then the expected status should be returned

      * -> Verify you can create the last interval in the item range
      Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-06T08:00:00Z   |
        | interval_source          | MEASURED                     |
        | user_estimated           | true                     |
        | utility_data            | true                     |
        | relevant_indicator       | true                      |
      Then the expected status should be returned

      * -> Verify you cannot create an interval after the item end
      Given I expect the next API call to return a status code of 400 and details of "interval_dttm_utc '2023-09-06T08:01:00Z' is after end date for settlement item"
      When I POST a settlement_item_interval with the following properties:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-06T08:01:00Z  |
        | interval_source          | MEASURED                     |
        | user_estimated           | true                     |
        | utility_data            | true                     |
        | relevant_indicator       | true                      |
      Then the expected status should be returned

      * -> Verify you can PUT first and last intervals
      Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
      When I PUT the settlement_item_interval with new values:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T08:01:00Z  |
        | interval_source          | UTILITY                     |
        | user_estimated           | false                     |
        | utility_data            | false                     |
        | relevant_indicator       | false                      |
        | change_comments          | Update some properties     |
      Then the expected status should be returned

      Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
      When I PUT the settlement_item_interval with new values:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-06T08:00:00Z  |
        | interval_source          | UTILITY                     |
        | user_estimated           | false                     |
        | utility_data            | false                     |
        | relevant_indicator       | false                      |
        | change_comments          | Update some properties     |
      Then the expected status should be returned

      * -> Verify PUT errors
      Given I expect the next API call to return a status code of 400 and details of "interval_dttm_utc '2023-09-05T07:59:00Z' is before or equal to start date for settlement item"
      When I PUT the settlement_item_interval with new values:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T07:59:00Z  |
        | interval_source          | UTILITY                     |
        | user_estimated           | false                     |
        | utility_data            | false                     |
        | relevant_indicator       | false                      |
        | change_comments          | Update some properties     |
      Then the expected status should be returned

      Given I expect the next API call to return a status code of 400 and details of "interval_dttm_utc '2023-09-05T08:00:00Z' is before or equal to start date for settlement item"
      When I PUT the settlement_item_interval with new values:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-05T08:00:00Z  |
        | interval_source          | UTILITY                     |
        | user_estimated           | false                     |
        | utility_data            | false                     |
        | relevant_indicator       | false                      |
        | change_comments          | Update some properties     |
      Then the expected status should be returned

      Given I expect the next API call to return a status code of 400 and details of "interval_dttm_utc '2023-09-06T08:01:00Z' is after end date for settlement item"
      When I PUT the settlement_item_interval with new values:
        | settlement_item_id       | <last-settlement-item-id> |
        | interval_dttm_utc        | 2023-09-06T08:01:00Z   |
        | interval_source          | UTILITY                     |
        | user_estimated           | false                     |
        | utility_data            | false                     |
        | relevant_indicator       | false                      |
        | change_comments          | Update some properties     |
      Then the expected status should be returned

      # Cleanup
      When I DELETE the settlement_item
      Then the DELETE settlement_item details should specify 1 settlement item and 2 settlement item intervals


      Scenario: Error cases

        Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found to delete for settlement item id"
        Given I set the last settlement_item id to 99a6d4e0-4655-4133-b190-8a23076732f5
        When I DELETE the settlement_item_intervals
        Then the expected status should be returned

        Given  I expect the next API call to return a status code of 400 and details of "settlement_item_id must match format 'uuid'"
        Given I set the last settlement_item id to foo
        When I DELETE the settlement_item_intervals
        Then the expected status should be returned


        # ==============================================================================
        # DELETE interval – grandparent settlement inputs_available_until_dttm_utc
        # ==============================================================================

  Scenario: DELETE interval is allowed when grandparent settlement inputs_available_until_dttm_utc is null
    When I POST a settlement with the following properties:
      | settlement_type                 | ONGOING_DATA_SUBMISSION                          |
      | settlement_subtype              | TVA event                                        |
      | start_dttm_utc                  | 2023-09-05T08:00:00Z                             |
      | end_dttm_utc                    | 2023-09-06T08:00:00Z                             |
      | event_id                        | <uuid>                                           |
      | description                     | QAA test: delete interval grandparent null       |
      | settlement_status               | PRELIMINARY                                      |
      | business_process_status         | NOT_STARTED                                      |
      | source_system_type              | NGP                                              |
      | inputs_available_until_dttm_utc | null                                             |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 1              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id | <last-settlement-item-id> |
      | interval_dttm_utc  | 2023-09-05T09:00:00Z      |
      | interval_source    | MEASURED                  |
      | user_estimated     | true                      |
      | utility_data       | true                      |
      | relevant_indicator | true                      |
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals

  # Cleanup
    When I DELETE the settlement_item
    When I DELETE the settlement


  Scenario: DELETE interval is allowed when grandparent settlement inputs_available_until_dttm_utc is in the future
    When I POST a settlement with the following properties:
      | settlement_type                 | ONGOING_DATA_SUBMISSION                          |
      | settlement_subtype              | TVA event                                        |
      | start_dttm_utc                  | 2023-09-05T08:00:00Z                             |
      | end_dttm_utc                    | 2023-09-06T08:00:00Z                             |
      | event_id                        | <uuid>                                           |
      | description                     | QAA test: delete interval grandparent future     |
      | settlement_status               | PRELIMINARY                                      |
      | business_process_status         | NOT_STARTED                                      |
      | source_system_type              | NGP                                              |
      | inputs_available_until_dttm_utc | 2126-06-17T20:00:00Z                             |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 1              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id | <last-settlement-item-id> |
      | interval_dttm_utc  | 2023-09-05T09:00:00Z      |
      | interval_source    | MEASURED                  |
      | user_estimated     | true                      |
      | utility_data       | true                      |
      | relevant_indicator | true                      |
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals

  # Cleanup
    When I DELETE the settlement_item
    When I DELETE the settlement


  Scenario: DELETE interval is blocked when grandparent settlement inputs_available_until_dttm_utc is in the past
    When I POST a settlement with the following properties:
      | settlement_type                 | ONGOING_DATA_SUBMISSION                          |
      | settlement_subtype              | TVA event                                        |
      | start_dttm_utc                  | 2023-09-05T08:00:00Z                             |
      | end_dttm_utc                    | 2023-09-06T08:00:00Z                             |
      | event_id                        | <uuid>                                           |
      | description                     | QAA test: delete interval grandparent past       |
      | settlement_status               | PRELIMINARY                                      |
      | business_process_status         | NOT_STARTED                                      |
      | source_system_type              | NGP                                              |
      | inputs_available_until_dttm_utc | 2021-06-17T20:00:00Z                             |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 1              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id | <last-settlement-item-id> |
      | interval_dttm_utc  | 2023-09-05T09:00:00Z      |
      | interval_source    | MEASURED                  |
      | user_estimated     | true                      |
      | utility_data       | true                      |
      | relevant_indicator | true                      |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I DELETE the settlement_item_intervals
    Then the expected status should be returned

    When I PATCH the settlement with new values:
      | settlement_id                  | <last-settlement-id>            |
      | inputs_available_until_dttm_utc | 2125-06-17T13:27:02.620Z       |
      | change_comments               | Set inputs_available_until     |
    And the settlement inputs_available_until_dttm_utc field should be set

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals

    When I DELETE the settlement_item
    When I DELETE the settlement