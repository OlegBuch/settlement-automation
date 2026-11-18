Feature: Performance test for complex hierarchy

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin
    Given I set the SQL INSERT intervals batch size to 200


  Scenario: Basic scenario

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | Complex hierarchy                               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: complex hierarchy |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # POST a master item and its intervals
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Item 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given I POST a set of 100 intervals for settlement_item_id Item1
    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    # POST two child items and their intervals
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Item1>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Item 1 Child 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | DER_FUEL_CELL                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1_Child1

    Given I POST a set of 100 intervals for settlement_item_id Item1_Child1
    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Item1>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Item 1 Child 2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | DER_FUEL_CELL                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1_Child2

    Given I POST a set of 100 intervals for settlement_item_id Item1_Child2
    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    # POST another master item and its intervals
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Item 2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-09-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item2

    Given I POST a set of 100 intervals for settlement_item_id Item2
    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    # Now DELETE the entire hierarchy
    When I DELETE the settlement
    Then the DELETE settlement details should specify 4 settlement items and 400 settlement item intervals

    # Verify all audit logs
    And all of the following stepdefs should pass:
    * changes should be recorded in the settlement audit log
    * changes should be recorded in the settlement_item audit log for Item1 with per_page: 200 direction: forward
    * changes should be recorded in the settlement_item audit log for Item1_Child1 with per_page: 200 direction: forward
    * changes should be recorded in the settlement_item audit log for Item1_Child2 with per_page: 200 direction: forward
    * changes should be recorded in the settlement_item audit log for Item2 with per_page: 200 direction: forward

    # Verify that GET does not return the deleted entities
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status

    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Item1 and include_sub_settlement_items = true
    Then the expected status should be returned
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Item1_Child1 and include_sub_settlement_items = true
    Then the expected status should be returned
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Item1_Child2 and include_sub_settlement_items = true
    Then the expected status should be returned
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Item2 and include_sub_settlement_items = true
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the expected status should be returned
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1_Child1> per_page: default direction: forward
    Then the expected status should be returned
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1_Child2> per_page: default direction: forward
    Then the expected status should be returned
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item2> per_page: default direction: forward
    Then the expected status should be returned
