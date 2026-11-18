Feature: GET settlement_items

  ITAPPSIT-3885: settlement api: add registration_set_id to settlement item
  ITAPPSIT-3452: settlement API: Support atlas_settlement_level_id as a query parameter to GET /settlement_items

  GET /settlement_items?{query_params}

  query_params:

  settlement_id
  settlement_level_id (exact match)
  settlement_item_status (exact match)
  submitted_indicator (exact match)

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  Scenario: Set up settlements for GET settlements scenarios

    #Given I DELETE settlement with the settlement_id 01b9a77e-d4e1-4c54-af14-e2e603b1428b
    #* stop
      Given I stop here because "Scenario only needs to be run once per env. Comment-out this stepdef if you want to set up a new env."

    # Settlement 1

    When I POST a settlement with the following properties:
        | settlement_type         | ENROLLMENT             |
        | settlement_subtype      | TVA event                           |
        | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
        | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
        | event_id                | QAA: 09/15/25: S1: Event 3 |
        | description             | QAA: GET items S1                      |
        | settlement_status       | PRELIMINARY                         |
        | business_process_status | NOT_STARTED                         |
        | source_system_type      | NGP                                 |
      Then the response should include the new settlement

      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        | settlement_level_id    | QAA: 09/15/25: GET items: Level 1             |
        | settlement_item_status | AWAITING_DATA        |
        | submitted_indicator    | true                 |
        | asset_type             | LOAD                 |
        | atlas_settlement_level_id | <uuid>              |
        | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
        | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
      Then the response should include the new settlement_item

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | ACCOUNT         |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 2             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
      | asset_type             | DER_BESS                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 3             |
      | settlement_item_status | AWAITING_DATA        |
      | submitted_indicator    | true                 |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | ACCOUNT         |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 4             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
      | asset_type             | DER_BESS                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    # Settlement 2

    When I POST a settlement with the following properties:
      | settlement_type         | MONTHLY_BILL_SAVINGS             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
      | event_id                | QAA: 09/15/25: S2: Event 3 |
      | description             | QAA: GET items S2                      |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 1             |
      | settlement_item_status | AWAITING_DATA        |
      | submitted_indicator    | true                 |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | ACCOUNT         |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 2             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
      | asset_type             | DER_BESS                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 3             |
      | settlement_item_status | AWAITING_DATA        |
      | submitted_indicator    | true                 |
      | asset_type             | LOAD                 |
      |atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | ACCOUNT         |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 4             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
      | asset_type             | DER_BESS                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    # Following settlement is used to test that items cannot be retrieved from deleted settlement unless include_deleted=true

    When I POST a settlement with the following properties:
      | settlement_type         | MONTHLY_BILL_SAVINGS             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
      | event_id                | QAA: 09/15/25: S3: Event 3 |
      | description             | QAA: GET items deleted                      |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA: 09/15/25: GET items deleted             |
      | settlement_item_status | AWAITING_DATA        |
      | submitted_indicator    | true                 |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    When I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 0 settlement item intervals


  Scenario: Query individual item properties

    # Verify all supported query properties individually

    Given a settlement exists for the event 'QAA: 09/15/25: S1: Event 3'
    When I call GET settlement_items with settlement_id '<last-settlement-id>'
    Then the response should contain 4 items
    And all items returned should match the query

    When I call GET settlement_items with settlement_level_id 'QAA: 09/15/25: GET items: Level 3'
    Then the response should contain 2 items
    And all items returned should match the query

    When I call GET settlement_items with settlement_item_status 'AWAITING_DATA'
    Then the response should contain more than 1 item
    And all items returned should match the query

    When I call GET settlement_items with submitted_indicator 'true'
    Then the response should contain more than 1 item
    And all items returned should match the query

    # Verify that exact match is required

    When I call GET settlement_items with settlement_level_id 'QAA: 09/15/25: GET items: LEVEL 3'
    Then the response should not contain any items

    # Verify submitted_indicator is boolean
    Given I expect the next API call to return a status code of 400 and details of "submitted_indicator must be boolean"
    When I call GET settlement_items with submitted_indicator 'foo'
    Then the expected status should be returned

     # Verify that unsupported properties return an error

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlement_items with settlement_level 'REGISTRATION'
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlement_items with asset_type 'LOAD'
    Then the expected status should be returned

    # Verify that items from deleted settlement cannot be retrieved unless include_deleted=true

    When I call GET settlement_items with settlement_level_id 'QAA: 09/15/25: GET items deleted'
    Then the response should not contain any items

    Given I set include_deleted=true
    When I call GET settlement_items with settlement_level_id 'QAA: 09/15/25: GET items deleted'
    Then the response should contain 1 item
    And all items returned should match the query


  Scenario: Query combinations of item properties

    Given a settlement exists for the event 'QAA: 09/15/25: S1: Event 3'

    When I call GET settlement_items with the following parameters:
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 2             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
    Then the response should contain 2 items
    And all items returned should match the query

    When I call GET settlement_items with the following parameters:
      | settlement_id         | <last-settlement-id>       |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 2             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
    Then the response should contain 1 item
    And all items returned should match the query

    Given I save the atlas_settlement_level_id from the last item in the GET response
    When I call GET settlement_items with the following parameters:
      | settlement_id         | <last-settlement-id>       |
      | settlement_level_id    | QAA: 09/15/25: GET items: Level 2             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
      | atlas_settlement_level_id | <last-atlas-settlement-level-id> |
    Then the response should contain 1 item
    And all items returned should match the query


  Scenario: Retrieve deleted settlement items

    Given I set include_deleted=missing
    When I call GET settlement_items with settlement_item_status 'AWAITING_DATA'
    Then the response should contain more than 1 item
    And only non-deleted items should be returned

    Given I set include_deleted=false
    When I call GET settlement_items with settlement_item_status 'AWAITING_DATA'
    Then the response should contain more than 1 item
    And only non-deleted items should be returned

    Given I set include_deleted=true
    When I call GET settlement_items with settlement_item_status 'AWAITING_DATA'
    Then the response should contain more than 1 item
    And all items returned should match the query
    And both deleted and non-deleted items should be returned
    # ITAPPSIT-3356: add "processing_status" text field
    And at least one item should have a non-null processing_status

    When I call GET settlement_items with the following parameters:
      | settlement_level_id    | QAA: 09/15/25: GET items deleted             |
      | settlement_item_status | AWAITING_DATA        |
    | include_deleted                | true                 |
    Then the response should contain 1 items
    And all items returned should match the query

    Given I save the atlas_settlement_level_id from the last item in the GET response
    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <last-atlas-settlement-level-id> |
      | include_deleted                | true                 |
    Then the response should contain 1 item
    And all items returned should match the query

    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <last-atlas-settlement-level-id> |
      | include_deleted                | false                 |
    Then the response should not contain any items


  Scenario:  ITAPPSIT-3452: settlement API: Support atlas_settlement_level_id as a query parameter to GET /settlement_items

    * -> Create two settlements with items having the target atlas_settlement_level_id. Include an item with a different id.
    * -> Also verifies that registration_set_id and portfolio_id are returned (ITAPPSIT-3885)

    Given I set the tag regId to a random uuid
    When I POST a settlement with the following properties:
      | settlement_type         | ENROLLMENT             |
      | settlement_subtype      | QAA Event                           |
      | start_dttm_utc          | 2025-01-10T00:00:00.000Z                |
      | end_dttm_utc            | 2025-01-20T00:30:00.000Z                |
      | event_id                | <uuid> |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | ITAPPSIT-3452            |
      | settlement_item_status | AWAITING_DATA        |
      | submitted_indicator    | true                 |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | start_dttm_utc          | 2025-01-10T00:00:00.000Z                |
      | end_dttm_utc            | 2025-01-11T00:00:00.000Z                |
    Then the response should include the new settlement_item

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | ITAPPSIT-3452             |
      | settlement_item_status | AWAITING_DATA        |
      | submitted_indicator    | true                 |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <regId>              |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | start_dttm_utc          | 2025-01-11T00:00:00.000Z                |
      | end_dttm_utc            | 2025-01-12T00:00:00.000Z                |
    Then the response should include the new settlement_item

    * -> Verify a single item is retrieved
    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <regId> |
    Then the response should contain 1 item
    And all items returned should match the query

    When I POST a settlement with the following properties:
      | settlement_type         | ENROLLMENT             |
      | settlement_subtype      | QAA Event                           |
      | start_dttm_utc          | 2025-01-10T00:00:00.000Z                |
      | end_dttm_utc            | 2025-01-20T00:30:00.000Z                |
      | event_id                | <uuid> |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | ITAPPSIT-3452             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | true                 |
      | asset_type             | DER_BESS                 |
      | atlas_settlement_level_id | <regId>              |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | start_dttm_utc          | 2025-01-12T00:00:00.000Z                |
      | end_dttm_utc            | 2025-01-15T00:00:00.000Z                |
    Then the response should include the new settlement_item

    * -> Verify two items are retrieved, from different settlements
    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <regId> |
    Then the response should contain 2 items
    And all items returned should match the query

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | ITAPPSIT-3452             |
      | settlement_item_status | AWAITING_DATA        |
      | submitted_indicator    | true                 |
      | asset_type             | DER_BESS                 |
      | atlas_settlement_level_id | <regId>              |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | start_dttm_utc          | 2025-01-15T00:00:00.000Z                |
      | end_dttm_utc            | 2025-01-20T00:00:00.000Z                |
    Then the response should include the new settlement_item

    * -> Verify three items are retrieved from different settlements
    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <regId> |
    Then the response should contain 3 items
    And all items returned should match the query

    * -> Verify that atlas_settlement_level_id can be included with other query parameters
    When I call GET settlement_items with the following parameters:
      | settlement_item_status | PRELIMINARY        |
      | start_dttm_utc          | 2025-01-12T00:00:00.000Z                |
      | end_dttm_utc            | 2025-01-15T00:00:00.000Z                |
      | atlas_settlement_level_id | <regId> |
    Then the response should contain 1 item
    And all items returned should match the query

    When I call GET settlement_items with the following parameters:
      | settlement_item_status | PRELIMINARY        |
      | start_dttm_utc          | 2025-01-12T00:00:00.000Z                |
      | end_dttm_utc            | 2025-01-15T00:00:00.000Z                |
      | atlas_settlement_level_id | <uuid> |
    Then the response should not contain any items

    * -> Delete the last settlement item and verify it is not retrieved unless include_deleted = true
    Given I DELETE the settlement_item

    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <regId> |
    Then the response should contain 2 items
    And all items returned should match the query

    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <regId> |
      | include_deleted                | true                 |
    Then the response should contain 3 items
    And all items returned should match the query

    * -> Delete the last settlement and verify none of its items are retrieved
    Given I DELETE the settlement
    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <regId> |
    Then the response should contain 1 items
    And all items returned should match the query
    And every item in the response should have the property asset_type set to "LOAD"

    * -> Delete the remaining settlement and verify no items are retrieved unless include_deleted = true
    Given I DELETE all settlements created in this scenario
    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <regId> |
    Then the response should not contain any items

    When I call GET settlement_items with the following parameters:
      | atlas_settlement_level_id | <regId> |
      | include_deleted                | true                 |
    Then the response should contain 3 items
    And all items returned should match the query


  Scenario: GET settlement_items and settlement_item_intervals errors

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlement_items with no query parameters
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlement_items with an invalid query parameter foo = BAR
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "data must have required property 'settlement_item_id'"
    When I call GET settlement_item_intervals with no query parameters
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "data must have required property 'settlement_item_id'"
    When I call GET settlement_item_intervals with an invalid query parameter foo = BAR
    Then the expected status should be returned
