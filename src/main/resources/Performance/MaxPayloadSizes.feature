Feature: Max payload sizes for settlement item intervals


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Maximum POST payload

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-10-01T00:00:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Maximum POST payload |
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
      | end_dttm_utc            | 2024-10-01T00:00:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    # Through experimentation, 1100 is close to the maximum number you can post through API Gateway
    Given I POST a set of 1100 intervals for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: 1000 direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I PUT an update for all of the intervals with settlement_item_id Item1
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: 1000 direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals
    And changes should be recorded in the settlement_item_intervals audit log with per_page: 2000 direction: forward

    Given I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 1100 settlement item intervals
