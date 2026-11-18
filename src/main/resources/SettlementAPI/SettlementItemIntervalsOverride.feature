Feature: Feature test for settlement item intervals – override fields

  Reference: <CONFLUENCE_URL>/display/PMENA/Settlement+API+-+Technical+Design

  <JIRA_URL>/browse/ITAPPSIT-3859: settlement api: add realtime_availability_kw_override and payment_value_override to settlement item intervals

  Background:
   Given I start with an empty context
   And I log in as a settlement API admin

  Scenario: POST and GET interval with override fields populated

    # Create parent settlement and item
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-05T09:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA test: overrides     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-05T09:00:00Z |
    Then the response should include the new settlement_item

    # POST interval with overrides
    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id                 | <last-settlement-item-id> |
      | interval_dttm_utc                  | 2023-09-05T08:05:00Z      |
      | interval_source                    | MEASURED                  |
      | user_estimated                     | true                      |
      | utility_data                       | true                      |
      | relevant_indicator                 | true                      |
      | realtime_availability_kw           | 14.0                      |
      | realtime_availability_kw_override  | 15.0                      |
      | payment_value                      | 100.0                     |
      | payment_value_override             | 110.0                     |
    Then the expected status should be returned

    # Verify via GET
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals
    And the last settlement_item_interval should have the following properties:
      | realtime_availability_kw          | 14.0  |
      | realtime_availability_kw_override | 15.0  |
      | payment_value                     | 100.0 |
      | payment_value_override            | 110.0 |

    # Cleanup
    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals

  Scenario: POST with missing overrides – fields stored as null and omitted from GET

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T10:00:00Z    |
      | end_dttm_utc            | 2023-09-05T11:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | Overrides missing       |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T10:00:00Z |
      | end_dttm_utc           | 2023-09-05T11:00:00Z |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id    | <last-settlement-item-id> |
      | interval_dttm_utc     | 2023-09-05T10:05:00Z      |
      | interval_source       | MEASURED                  |
      | user_estimated        | true                      |
      | utility_data          | true                      |
      | relevant_indicator    | true                      |
      | realtime_availability_kw | 14.0                   |
      | payment_value         | 100.0                     |
      # No override fields
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals
    And the last settlement_item_interval should not include override fields

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals

  Scenario: PUT clears override fields when omitted

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T12:00:00Z    |
      | end_dttm_utc            | 2023-09-05T13:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | Overrides PUT clear     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T12:00:00Z |
      | end_dttm_utc           | 2023-09-05T13:00:00Z |
    Then the response should include the new settlement_item

    # Seed interval with overrides
    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id                 | <last-settlement-item-id> |
      | interval_dttm_utc                  | 2023-09-05T12:05:00Z      |
      | interval_source                    | MEASURED                  |
      | user_estimated                     | true                      |
      | utility_data                       | true                      |
      | relevant_indicator                 | true                      |
      | realtime_availability_kw           | 14.0                      |
      | realtime_availability_kw_override  | 15.0                      |
      | payment_value                      | 100.0                     |
      | payment_value_override             | 110.0                     |
    Then the expected status should be returned

    # PUT without override fields – overrides should be set to null
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id   | <last-settlement-item-id> |
      | interval_dttm_utc    | 2023-09-05T12:05:00Z      |
      | interval_source      | UTILITY                   |
      | user_estimated       | false                     |
      | utility_data         | false                     |
      | relevant_indicator   | false                     |
      | change_comments      | Clear override fields     |
      # No override fields in PUT body
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals
    And the last settlement_item_interval should not include override fields

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals

  Scenario: PATCH updates only override fields

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T14:00:00Z    |
      | end_dttm_utc            | 2023-09-05T15:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | Overrides PATCH         |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T14:00:00Z |
      | end_dttm_utc           | 2023-09-05T15:00:00Z |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id        | <last-settlement-item-id> |
      | interval_dttm_utc         | 2023-09-05T14:05:00.000Z     |
      | interval_source           | MEASURED                  |
      | user_estimated            | true                      |
      | utility_data              | true                      |
      | relevant_indicator        | true                      |
      | realtime_availability_kw  | 14.0                      |
      | payment_value             | 100.0                     |
    Then the expected status should be returned

    # PATCH just the overrides
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T14:05:00.000Z      |
      | realtime_availability_kw_override | 25.5                      |
      | payment_value_override            | 150.5                   |
      | change_comments                   | Update override fields    |
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    And the last updated settlement_item_interval should have the following properties:
      | realtime_availability_kw_override | 25.5 |
      | payment_value_override            | 150.5  |
      | realtime_availability_kw          | 14 |
      | payment_value                     | 100 |

    And the settlement_item_intervals audit log should contain override entries for the last interval

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals

  Scenario: Check override fields support return nulls with POST, PUT, and PATCH
  # Setup a basic settlement and item
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-05T09:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA test: overrides null     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-05T09:00:00Z |
    Then the response should include the new settlement_item

  # POST interval with explicit null overrides
    Given I expect the next API call to return a status code of 200 and details of "Successfully created 1 settlement_item_intervals"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:15:00.000Z  |
      | interval_source                   | MEASURED                  |
      | user_estimated                     | true                      |
      | utility_data                       | true                      |
      | relevant_indicator                 | true                      |
      | realtime_availability_kw          | 14                        |
      | payment_value                     | 100                       |
      | realtime_availability_kw_override | null                      |
      | payment_value_override            | null                      |
      | change_comments                   | POST null overrides       |
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    And the last updated settlement_item_interval should have the following properties:
      | realtime_availability_kw_override | null |
      | payment_value_override            | null |
      | realtime_availability_kw          | 14   |
      | payment_value                     | 100  |

  # PUT same interval, explicitly keeping overrides null
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:15:00.000Z  |
      | interval_source                   | UTILITY                   |
      | user_estimated                     | false                      |
      | utility_data                       | false                      |
      | relevant_indicator                 | false                      |
      | realtime_availability_kw_override | null                      |
      | payment_value_override            | null                      |
      | realtime_availability_kw          | 14   |
      | payment_value                     | 100  |
      | change_comments                   | PUT keep null overrides   |
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    And the last updated settlement_item_interval should have the following properties:
      | realtime_availability_kw_override | null |
      | payment_value_override            | null |
      | realtime_availability_kw          | 14   |
      | payment_value                     | 100  |

      # PATCH same interval, overrides still null
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated 1 settlement_item_intervals"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:15:00.000Z  |
      | realtime_availability_kw_override | null                      |
      | payment_value_override            | null                      |
      | change_comments                   | PATCH keep null overrides |
    Then the expected status should be returned

    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    And the last updated settlement_item_interval should have the following properties:
      | realtime_availability_kw_override | null |
      | payment_value_override            | null |
      | realtime_availability_kw          | 14   |
      | payment_value                     | 100  |

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals


  Scenario: Check POST (payment_value_override/realtime_availability_kw_override) and PUT payment_value_override property with incorrect values - not allowed (strings, booleans, empty)
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-05T09:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA test: overrides null     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-05T09:00:00Z |
    Then the response should include the new settlement_item

    # POST with invalid boolean overrides payment_value_override - boolean value
    Given I expect the next API call to return a status code of 400 and details of "payment_value_override must be a numerical string"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:30:00.000Z  |
      | interval_source                   | MEASURED                  |
      | user_estimated                    | true                      |
      | utility_data                      | true                      |
      | relevant_indicator                | true                      |
      | realtime_availability_kw_override | 200              |
      | payment_value_override            | false              |
      | realtime_availability_kw          | 10                        |
      | payment_value                     | 20                        |
      | change_comments                   | POST invalid string overrides |

    # POST with invalid string overrides realtime_availability_kw_override - text value
    Given I expect the next API call to return a status code of 400 and details of "realtime_availability_kw_override must be number,null"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:30:00.000Z  |
      | interval_source                   | MEASURED                  |
      | user_estimated                    | true                      |
      | utility_data                      | true                      |
      | relevant_indicator                | true                      |
      | realtime_availability_kw_override | not-a-number              |
      | payment_value_override            | 100              |
      | realtime_availability_kw          | 10                        |
      | payment_value                     | 20                        |
      | change_comments                   | POST invalid string overrides |

       # POST with invalid boolean overrides payment_value_override - text value
    Given I expect the next API call to return a status code of 400 and details of "payment_value_override must be a numerical string"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:30:00.000Z  |
      | interval_source                   | MEASURED                  |
      | user_estimated                    | true                      |
      | utility_data                      | true                      |
      | relevant_indicator                | true                      |
      | realtime_availability_kw_override | 200              |
      | payment_value_override            | text              |
      | realtime_availability_kw          | 10                        |
      | payment_value                     | 20                        |
      | change_comments                   | POST invalid string overrides |


        # POST with invalid boolean overrides payment_value_override - empty
    Given I expect the next API call to return a status code of 400 and details of "payment_value_override must be a numerical string"
    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:30:00.000Z  |
      | interval_source                   | MEASURED                  |
      | user_estimated                    | true                      |
      | utility_data                      | true                      |
      | relevant_indicator                | true                      |
      | realtime_availability_kw_override | 200              |
      | payment_value_override            |               |
      | realtime_availability_kw          | 10                        |
      | payment_value                     | 20                        |
      | change_comments                   | POST invalid string overrides |


    # PUT with invalid boolean overrides payment_value_override
    Given I expect the next API call to return a status code of 400 and details of "payment_value_override must be a numerical string"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:30:00.000Z  |
      | interval_source                   | UTILITY                   |
      | user_estimated                    | false                     |
      | utility_data                      | false                     |
      | relevant_indicator                | false                     |
      | realtime_availability_kw_override | 100                      |
      | payment_value_override            | false                     |
      | realtime_availability_kw          | 10                      |
      | payment_value                     | 100                     |
      | change_comments                   | PUT invalid boolean overrides |

    # PUT with invalid string overrides payment_value_override
    Given I expect the next API call to return a status code of 400 and details of "payment_value_override must be a numerical string"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:30:00.000Z  |
      | interval_source                   | UTILITY                   |
      | user_estimated                    | false                     |
      | utility_data                      | false                     |
      | relevant_indicator                | false                     |
      | realtime_availability_kw_override | 100                      |
      | payment_value_override            | test string                     |
      | realtime_availability_kw          | 10                      |
      | payment_value                     | 100                     |
      | change_comments                   | PUT invalid boolean overrides |

    # PUT with invalid empty overrides payment_value_override
    Given I expect the next API call to return a status code of 400 and details of "payment_value_override must be a numerical string"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:30:00.000Z  |
      | interval_source                   | UTILITY                   |
      | user_estimated                    | false                     |
      | utility_data                      | false                     |
      | relevant_indicator                | false                     |
      | realtime_availability_kw_override | 100                      |
      | payment_value_override            |                      |
      | realtime_availability_kw          | 10                      |
      | payment_value                     | 100                     |
      | change_comments                   | PUT invalid boolean overrides |


    Given I DELETE the settlement

  Scenario: Check PUT realtime_availability_kw_override property with incorrect values - not allowed (strings, booleans)
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-05T09:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA test: overrides null     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-05T09:00:00Z |
    Then the response should include the new settlement_item

    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T08:05:00Z   |
      | interval_source          | MEASURED                     |
      | user_estimated           | true                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    # PUT with invalid string overrides
    Given I expect the next API call to return a status code of 400 and details of "realtime_availability_kw_override must be number,null"
    When I PUT the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:05:00.000Z  |
      | interval_source                   | UTILITY                   |
      | user_estimated                    | true                     |
      | utility_data                      | false                     |
      | relevant_indicator                | false                     |
      | realtime_availability_kw_override | string                      |
      | payment_value_override            | 110                     |
      | realtime_availability_kw          | 10                      |
      | payment_value                     | 100                     |
      | change_comments                   | PUT invalid boolean overrides |


    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals

  Scenario: Check PATCH realtime_availability_kw_override property with incorrect values - not allowed (strings, booleans)
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-05T09:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA test: overrides null     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-05T09:00:00Z |
    Then the response should include the new settlement_item

    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T08:06:00Z   |
      | interval_source          | MEASURED                     |
      | user_estimated           | true                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    #PATCH with invalid overrides (string)
    Given I expect the next API call to return a status code of 400 and details of "realtime_availability_kw_override must be number,null"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:06:00.000Z  |
      | realtime_availability_kw_override | string                 |
      | payment_value_override            |     100     |
      | change_comments                   | PATCH invalid string overrides |

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals

  Scenario: Check PATCH payment_value_override property with incorrect values - not allowed (strings, booleans, empty)
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-05T09:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA test: overrides null     |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc         | 2023-09-05T08:00:00Z |
      | end_dttm_utc           | 2023-09-05T09:00:00Z |
    Then the response should include the new settlement_item

    When I POST a settlement_item_interval with the following properties:
      | settlement_item_id       | <last-settlement-item-id> |
      | interval_dttm_utc        | 2023-09-05T08:07:00Z   |
      | interval_source          | MEASURED                     |
      | user_estimated           | true                     |
      | utility_data            | true                     |
      | relevant_indicator       | true                      |
    Then the expected status should be returned

    #PATCH with invalid overrides (string)
    Given I expect the next API call to return a status code of 400 and details of "invalid decimal value for payment_value_override"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:07:00.000Z  |
      | realtime_availability_kw_override | 300                 |
      | payment_value_override            |     text     |
      | change_comments                   | PATCH invalid string overrides |

    #PATCH with invalid overrides (boolean)
    Given I expect the next API call to return a status code of 400 and details of "invalid decimal value for payment_value_override"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:07:00.000Z  |
      | realtime_availability_kw_override |       400           |
      | payment_value_override            |     false     |
      | change_comments                   | PATCH invalid string overrides |

    #PATCH with invalid overrides (empty)
    Given I expect the next API call to return a status code of 400 and details of "invalid decimal value for payment_value_override"
    When I PATCH the settlement_item_interval with new values:
      | settlement_item_id                | <last-settlement-item-id> |
      | interval_dttm_utc                 | 2023-09-05T08:07:00.000Z  |
      | realtime_availability_kw_override |       400           |
      | payment_value_override            |          |
      | change_comments                   | PATCH invalid string overrides |


    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1 settlement item intervals
