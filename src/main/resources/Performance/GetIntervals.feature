Feature: Performance tests for GET intervals

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  Scenario: Basic scenario

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-07-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-07-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for interval performance |
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
      | atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-07-05T08:00:00Z                     |
      | end_dttm_utc            | 2024-07-05T08:30:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given I set the SQL INSERT intervals batch size to 200
    Given I POST a set of batchSize intervals for settlement_item_id Item1

    When I call GET settlement_item_intervals_summary
    Then the GET settlement_item_intervals_summary result should be correct

    Given I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # Cleanup
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify the expected number of settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
